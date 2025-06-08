// Utility for dynamic URL configuration based on environment and platform
// This handles the Android emulator URL mapping issue

class PlatformUrlService {
    /**
     * Get the appropriate base URL based on environment and platform
     * @param {Object} options - Configuration options
     * @param {string} options.defaultUrl - Default URL (usually localhost)
     * @param {string} options.environment - Current environment (development, production)
     * @param {string} options.platform - Target platform (android, ios, web)
     * @returns {string} Appropriate base URL
     */
    static getBaseUrl(options = {}) {
        const {
            defaultUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`,
            environment = process.env.NODE_ENV || 'development',
            platform = process.env.TARGET_PLATFORM || 'web'
        } = options;

        // In development, check if we need to use Android emulator mapping
        if (environment === 'development') {
            // If BASE_URL is explicitly set, use it (configured for target platform)
            if (process.env.BASE_URL) {
                return process.env.BASE_URL;
            }
            
            // Default behavior for different platforms
            const port = process.env.PORT || 3000;
            switch (platform.toLowerCase()) {
                case 'android':
                    return `http://10.0.2.2:${port}`;
                case 'ios':
                case 'web':
                case 'desktop':
                default:
                    return `http://localhost:${port}`;
            }
        }

        // In production, use the configured URL or default
        return defaultUrl;
    }

    /**
     * Build complete image URL
     * @param {string} filename - Image filename
     * @param {Object} options - URL options
     * @returns {string|null} Complete image URL or null
     */
    static buildImageUrl(filename, options = {}) {
        if (!filename) return null;
        
        const baseUrl = this.getBaseUrl(options);
        const uploadDir = process.env.UPLOAD_FOLDER || 'uploads';
        return `${baseUrl}/${uploadDir}/${filename}`;
    }

    /**
     * Transform localhost URLs to Android emulator URLs if needed
     * Used for URL transformation in responses
     * @param {string} url - Original URL
     * @returns {string} Transformed URL
     */
    static transformForAndroidEmulator(url) {
        if (!url) return url;
        
        // Only transform in development for Android
        const isAndroidDev = process.env.NODE_ENV === 'development' && 
                            process.env.TARGET_PLATFORM === 'android';
        
        if (isAndroidDev && url.includes('localhost:')) {
            return url.replace(/localhost:/g, '10.0.2.2:');
        }
        
        return url;
    }
}

module.exports = PlatformUrlService;
