// Backend Clean Architecture Structure
src/
├── core/                          # Núcleo da aplicação
│   ├── domain/                    # Camada de Domínio
│   │   ├── entities/             # Entidades de negócio
│   │   │   ├── stock-item.js
│   │   │   ├── document.js
│   │   │   ├── customer.js
│   │   │   ├── supplier.js
│   │   │   ├── store.js
│   │   │   └── user.js
│   │   ├── repositories/         # Contratos dos repositórios
│   │   │   ├── stock-repository.js
│   │   │   ├── document-repository.js
│   │   │   ├── customer-repository.js
│   │   │   ├── supplier-repository.js
│   │   │   ├── store-repository.js
│   │   │   └── auth-repository.js
│   │   ├── services/             # Serviços de domínio
│   │   │   ├── stock-service.js
│   │   │   ├── document-service.js
│   │   │   ├── balance-calculator.js
│   │   │   └── inventory-validator.js
│   │   └── value-objects/        # Objetos de valor
│   │       ├── money.js
│   │       ├── quantity.js
│   │       ├── document-type.js
│   │       └── date-range.js
│   ├── application/              # Camada de Aplicação (Use Cases)
│   │   ├── usecases/            # Casos de uso
│   │   │   ├── stock/
│   │   │   │   ├── get-stock-items.js
│   │   │   │   ├── create-stock-item.js
│   │   │   │   ├── update-stock-item.js
│   │   │   │   └── delete-stock-item.js
│   │   │   ├── documents/
│   │   │   │   ├── get-documents.js
│   │   │   │   ├── create-document.js
│   │   │   │   ├── update-document.js
│   │   │   │   └── calculate-balance-sheet.js
│   │   │   ├── customers/
│   │   │   ├── suppliers/
│   │   │   ├── stores/
│   │   │   └── auth/
│   │   ├── dto/                 # Data Transfer Objects
│   │   │   ├── stock-item-dto.js
│   │   │   ├── document-dto.js
│   │   │   ├── customer-dto.js
│   │   │   └── balance-sheet-dto.js
│   │   └── validators/          # Validadores de entrada
│   │       ├── stock-validator.js
│   │       ├── document-validator.js
│   │       └── auth-validator.js
│   └── infrastructure/           # Camada de Infraestrutura
│       ├── database/            # Acesso a dados
│       │   ├── sqlite/
│       │   │   ├── connection.js
│       │   │   ├── migrations/
│       │   │   └── repositories/
│       │   │       ├── stock-repository-impl.js
│       │   │       ├── document-repository-impl.js
│       │   │       ├── customer-repository-impl.js
│       │   │       ├── supplier-repository-impl.js
│       │   │       └── auth-repository-impl.js
│       │   └── models/          # Modelos de dados (ORM)
│       │       ├── stock-item-model.js
│       │       ├── document-model.js
│       │       ├── customer-model.js
│       │       └── supplier-model.js
│       ├── external/            # Serviços externos
│       │   ├── email-service.js
│       │   ├── file-storage.js
│       │   └── pdf-generator.js
│       └── security/            # Segurança
│           ├── jwt-service.js
│           ├── encryption.js
│           └── rate-limiter.js
├── presentation/                 # Camada de Apresentação (API)
│   ├── controllers/             # Controladores REST
│   │   ├── stock-controller.js
│   │   ├── document-controller.js
│   │   ├── customer-controller.js
│   │   ├── supplier-controller.js
│   │   ├── store-controller.js
│   │   └── auth-controller.js
│   ├── routes/                  # Definição das rotas
│   │   ├── api/
│   │   │   ├── v1/
│   │   │   │   ├── stock-routes.js
│   │   │   │   ├── document-routes.js
│   │   │   │   ├── customer-routes.js
│   │   │   │   ├── supplier-routes.js
│   │   │   │   ├── store-routes.js
│   │   │   │   └── auth-routes.js
│   │   │   └── index.js
│   │   └── index.js
│   ├── middleware/              # Middlewares
│   │   ├── auth-middleware.js
│   │   ├── validation-middleware.js
│   │   ├── error-middleware.js
│   │   ├── cors-middleware.js
│   │   └── logging-middleware.js
│   └── validators/              # Validadores de request
│       ├── stock-request-validator.js
│       ├── document-request-validator.js
│       └── auth-request-validator.js
├── shared/                      # Código compartilhado
│   ├── constants/              # Constantes
│   │   ├── app-constants.js
│   │   ├── error-codes.js
│   │   └── http-status.js
│   ├── utils/                  # Utilitários
│   │   ├── logger.js
│   │   ├── date-utils.js
│   │   ├── string-utils.js
│   │   └── response-utils.js
│   ├── errors/                 # Classes de erro customizadas
│   │   ├── base-error.js
│   │   ├── validation-error.js
│   │   ├── not-found-error.js
│   │   └── unauthorized-error.js
│   └── events/                 # Sistema de eventos
│       ├── event-emitter.js
│       └── event-handlers/
├── config/                     # Configurações
│   ├── database.js
│   ├── server.js
│   ├── security.js
│   └── environment.js
└── server.js                   # Ponto de entrada

# Arquivos antigos (manter para migração gradual)
controllers/                    # DEPRECATED - mover para presentation/controllers
data/                          # DEPRECATED - mover para core/infrastructure/database
middleware/                    # DEPRECATED - mover para presentation/middleware
routes/                        # DEPRECATED - mover para presentation/routes
utils/                         # DEPRECATED - mover para shared/utils
