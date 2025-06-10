// src/middleware/uploadMiddleware.js

const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Lê o diretório de upload da variável de ambiente ou usa um padrão
const UPLOAD_DIR = process.env.UPLOAD_FOLDER || 'uploads';
const uploadPath = path.join(__dirname, '../../', UPLOAD_DIR); // Caminho absoluto

// Cria o diretório de uploads se ele não existir
if (!fs.existsSync(uploadPath)) {
    try {
        fs.mkdirSync(uploadPath, { recursive: true }); // recursive: true cria diretórios pais se necessário
        console.log(`Diretório de uploads criado em: ${uploadPath}`);
    } catch (err) {
        console.error(`Erro ao criar diretório de uploads (${uploadPath}):`, err);
        // Decide se quer parar a aplicação ou continuar sem upload funcional
        // process.exit(1); // Descomente para parar se o diretório for essencial
    }
} else {
     console.log(`Usando diretório de uploads existente: ${uploadPath}`);
}


// Configuração de armazenamento do Multer
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, uploadPath); // Define o diretório de destino
    },    filename: function (req, file, cb) {
        // Define um nome de arquivo único para evitar colisões
        const itemId = req.params.itemId || 'unknown'; // Pega o ID do item da rota (corrigido: params.itemId em vez de params.id)
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const extension = path.extname(file.originalname); // Pega a extensão original
        cb(null, `item-${itemId}-${uniqueSuffix}${extension}`);
    }
});

// Filtro de arquivo: Aceitar apenas imagens e alguns tipos específicos
const fileFilter = (req, file, cb) => {
    // --- DEBUGGING ---
    console.log('--- Informações do Arquivo Recebido ---');
    console.log('Nome original:', file.originalname);
    console.log('MIME Type recebido:', file.mimetype);
    console.log('Encoding:', file.encoding);
    console.log('Tamanho:', file.size);
    console.log('---------------------------------------');
    // --- FIM DEBUGGING ---

    // Lista de tipos MIME aceitos (imagens)
    const allowedMimeTypes = [
        'image/jpeg',
        'image/jpg', 
        'image/png',
        'image/gif',
        'image/bmp',
        'image/webp',
        'image/svg+xml'
    ];

    if (file.mimetype && allowedMimeTypes.includes(file.mimetype.toLowerCase())) {
        console.log(`MIME Type "${file.mimetype}" aceito.`);
        cb(null, true); // Aceitar arquivo
    } else {
        console.log(`MIME Type "${file.mimetype}" REJEITADO.`);
        // Rejeitar arquivo, passando o erro específico
        cb(new Error(`Tipo de arquivo inválido: ${file.mimetype}. Apenas imagens são permitidas (JPEG, PNG, GIF, BMP, WebP, SVG).`), false);
    }
};

// Cria a instância do multer com as configurações
const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 1024 * 1024 * 10, // Limite de 10MB
        files: 1 // Apenas um arquivo por vez
    }
});

// Middleware personalizado para capturar erros do multer
const uploadWithErrorHandling = (req, res, next) => {
    upload.single('image')(req, res, (err) => {
        if (err instanceof multer.MulterError) {
            console.error('Erro do Multer:', err);
            if (err.code === 'LIMIT_FILE_SIZE') {
                return res.status(400).json({
                    error: 'Arquivo muito grande. Tamanho máximo permitido: 10MB.',
                    status: 'error'
                });
            } else if (err.code === 'LIMIT_FILE_COUNT') {
                return res.status(400).json({
                    error: 'Muitos arquivos. Envie apenas um arquivo por vez.',
                    status: 'error'
                });
            } else {
                return res.status(400).json({
                    error: `Erro no upload: ${err.message}`,
                    status: 'error'
                });
            }
        } else if (err) {
            console.error('Erro customizado:', err);
            return res.status(400).json({
                error: err.message,
                status: 'error'
            });
        }
        next();
    });
};

module.exports = uploadWithErrorHandling; // Exporta o middleware com tratamento de erro