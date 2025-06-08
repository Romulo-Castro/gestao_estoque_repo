// Response Utilities
class ResponseUtils {
    static success(res, data = null, message = 'Success', statusCode = 200) {
        return res.status(statusCode).json({
            status: 'success',
            message,
            data,
            timestamp: new Date().toISOString()
        });
    }

    static error(res, message = 'Internal Server Error', statusCode = 500, errors = null) {
        const response = {
            status: 'error',
            message,
            timestamp: new Date().toISOString()
        };

        if (errors) {
            response.errors = errors;
        }

        if (process.env.NODE_ENV === 'development' && statusCode >= 500) {
            // Include additional debug info in development
            response.debug = {
                statusCode,
                environment: process.env.NODE_ENV
            };
        }

        return res.status(statusCode).json(response);
    }

    static validationError(res, errors, message = 'Validation failed') {
        return this.error(res, message, 400, errors);
    }

    static notFound(res, resource = 'Resource') {
        return this.error(res, `${resource} not found`, 404);
    }

    static unauthorized(res, message = 'Unauthorized') {
        return this.error(res, message, 401);
    }

    static forbidden(res, message = 'Forbidden') {
        return this.error(res, message, 403);
    }

    static conflict(res, message = 'Conflict') {
        return this.error(res, message, 409);
    }

    static tooManyRequests(res, message = 'Too many requests') {
        return this.error(res, message, 429);
    }

    static paginated(res, data, pagination, message = 'Success') {
        return res.status(200).json({
            status: 'success',
            message,
            data,
            pagination: {
                page: pagination.page,
                limit: pagination.limit,
                total: pagination.total,
                totalPages: Math.ceil(pagination.total / pagination.limit),
                hasNext: pagination.page < Math.ceil(pagination.total / pagination.limit),
                hasPrev: pagination.page > 1
            },
            timestamp: new Date().toISOString()
        });
    }

    static created(res, data, message = 'Created successfully') {
        return this.success(res, data, message, 201);
    }

    static noContent(res) {
        return res.status(204).send();
    }

    static badRequest(res, message = 'Bad request', errors = null) {
        return this.error(res, message, 400, errors);
    }

    static internalError(res, message = 'Internal server error') {
        return this.error(res, message, 500);
    }

    static notImplemented(res, message = 'Not implemented') {
        return this.error(res, message, 501);
    }

    static serviceUnavailable(res, message = 'Service unavailable') {
        return this.error(res, message, 503);
    }
}

module.exports = { ResponseUtils };
