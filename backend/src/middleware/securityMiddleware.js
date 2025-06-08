// src/middleware/securityMiddleware.js
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const morgan = require('morgan');

// Rate limiting configurations
const generalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: {
        error: 'Muitas tentativas. Tente novamente em 15 minutos.',
        status: 'error'
    },
    standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
    legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});

const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5, // limit each IP to 5 requests per windowMs for auth endpoints
    message: {
        error: 'Muitas tentativas de autenticação. Tente novamente em 15 minutos.',
        status: 'error'
    },
    standardHeaders: true,
    legacyHeaders: false,
});

const uploadLimiter = rateLimit({
    windowMs: 5 * 60 * 1000, // 5 minutes
    max: 10, // limit each IP to 10 uploads per 5 minutes
    message: {
        error: 'Muitos uploads. Tente novamente em 5 minutos.',
        status: 'error'
    },
    standardHeaders: true,
    legacyHeaders: false,
});

// Helmet configuration for security headers
const helmetConfig = helmet({
    crossOriginEmbedderPolicy: false, // Disable for development/API usage
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            scriptSrc: ["'self'"],
            imgSrc: ["'self'", "data:", "https:"],
            connectSrc: ["'self'"],
            fontSrc: ["'self'"],
            objectSrc: ["'none'"],
            mediaSrc: ["'self'"],
            frameSrc: ["'none'"],
        },
    },
    hsts: {
        maxAge: 31536000, // 1 year
        includeSubDomains: true,
        preload: true
    }
});

// Morgan logging configuration
const morganFormat = process.env.NODE_ENV === 'production' 
    ? 'combined'
    : 'dev';

const securityLogger = morgan(morganFormat, {
    skip: function (req, res) {
        // Skip logging for successful health checks
        return res.statusCode < 400 && req.url === '/health';
    }
});

// Custom middleware to log security events
const logSecurityEvent = (event, req, additionalInfo = {}) => {
    const logData = {
        timestamp: new Date().toISOString(),
        event,
        ip: req.ip || req.connection.remoteAddress,
        userAgent: req.get('User-Agent'),
        url: req.originalUrl,
        method: req.method,
        userId: req.user?.userId,
        storeId: req.params?.storeId,
        ...additionalInfo
    };
    
    console.log('SECURITY_EVENT:', JSON.stringify(logData));
};

// Middleware to validate file uploads
const validateFileUpload = (req, res, next) => {
    if (!req.file && !req.files) {
        return next(); // No file uploaded, continue
    }

    const file = req.file || (req.files && req.files[0]);
    if (!file) {
        return next();
    }

    // Check file size (limit to 10MB)
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (file.size > maxSize) {
        logSecurityEvent('FILE_UPLOAD_SIZE_EXCEEDED', req, { fileSize: file.size });
        return res.status(413).json({
            status: 'error',
            message: 'Arquivo muito grande. Tamanho máximo: 10MB'
        });
    }

    // Check file type (only allow specific types)
    const allowedMimeTypes = [
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp',
        'application/pdf',
        'text/csv',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    ];

    if (!allowedMimeTypes.includes(file.mimetype)) {
        logSecurityEvent('FILE_UPLOAD_INVALID_TYPE', req, { mimetype: file.mimetype });
        return res.status(400).json({
            status: 'error',
            message: 'Tipo de arquivo não permitido'
        });
    }

    // Check filename for suspicious patterns
    const suspiciousPatterns = [
        /\.\./,  // Directory traversal
        /\//,    // Path separators
        /\\/,    // Windows path separators
        /[<>:"|?*]/,  // Invalid filename characters
        /\.exe$/i,    // Executable files
        /\.bat$/i,    // Batch files
        /\.cmd$/i,    // Command files
        /\.sh$/i,     // Shell scripts
        /\.php$/i,    // PHP files
        /\.js$/i,     // JavaScript files (in uploads)
        /\.html$/i,   // HTML files
    ];

    const isSuspicious = suspiciousPatterns.some(pattern => pattern.test(file.originalname));
    if (isSuspicious) {
        logSecurityEvent('FILE_UPLOAD_SUSPICIOUS_NAME', req, { filename: file.originalname });
        return res.status(400).json({
            status: 'error',
            message: 'Nome de arquivo inválido'
        });
    }

    logSecurityEvent('FILE_UPLOAD_SUCCESS', req, { 
        filename: file.originalname,
        mimetype: file.mimetype,
        size: file.size
    });

    next();
};

// Middleware to detect and log suspicious requests
const detectSuspiciousActivity = (req, res, next) => {
    const suspiciousPatterns = [
        /(\<|%3C)(\s*)script/i,  // XSS attempts
        /union.*select/i,         // SQL injection attempts
        /\.\.\//,                 // Directory traversal
        /etc\/passwd/i,           // Linux system file access
        /cmd\.exe/i,              // Windows command execution
        /eval\(/i,                // Code evaluation attempts
    ];

    const checkString = `${req.url} ${JSON.stringify(req.query)} ${JSON.stringify(req.body)}`;
    
    const isSuspicious = suspiciousPatterns.some(pattern => pattern.test(checkString));
    if (isSuspicious) {
        logSecurityEvent('SUSPICIOUS_REQUEST_DETECTED', req, { 
            query: req.query,
            body: Object.keys(req.body || {})
        });
    }

    next();
};

module.exports = {
    generalLimiter,
    authLimiter,
    uploadLimiter,
    helmetConfig,
    securityLogger,
    logSecurityEvent,
    validateFileUpload,
    detectSuspiciousActivity
};
