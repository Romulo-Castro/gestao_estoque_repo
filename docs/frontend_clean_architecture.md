// Core - Domain Layer
lib/
├── core/                           # Núcleo da aplicação (Clean Architecture)
│   ├── domain/                     # Camada de Domínio (Business Logic)
│   │   ├── entities/              # Entidades de negócio
│   │   │   ├── stock_item.dart
│   │   │   ├── document.dart
│   │   │   ├── customer.dart
│   │   │   ├── supplier.dart
│   │   │   ├── store.dart
│   │   │   └── user.dart
│   │   ├── repositories/          # Contratos dos repositórios
│   │   │   ├── stock_repository.dart
│   │   │   ├── document_repository.dart
│   │   │   ├── customer_repository.dart
│   │   │   ├── supplier_repository.dart
│   │   │   ├── store_repository.dart
│   │   │   └── auth_repository.dart
│   │   ├── usecases/             # Casos de uso (Business Logic)
│   │   │   ├── stock/
│   │   │   │   ├── get_stock_items.dart
│   │   │   │   ├── create_stock_item.dart
│   │   │   │   ├── update_stock_item.dart
│   │   │   │   └── delete_stock_item.dart
│   │   │   ├── documents/
│   │   │   │   ├── get_documents.dart
│   │   │   │   ├── create_document.dart
│   │   │   │   ├── update_document.dart
│   │   │   │   └── get_balance_sheet.dart
│   │   │   ├── customers/
│   │   │   ├── suppliers/
│   │   │   ├── stores/
│   │   │   └── auth/
│   │   └── value_objects/         # Objetos de valor
│   │       ├── document_type.dart
│   │       ├── money.dart
│   │       ├── quantity.dart
│   │       └── date_range.dart
│   ├── data/                      # Camada de Dados (Infrastructure)
│   │   ├── datasources/           # Fontes de dados
│   │   │   ├── remote/           # APIs remotas
│   │   │   │   ├── api_client.dart
│   │   │   │   ├── stock_remote_datasource.dart
│   │   │   │   ├── document_remote_datasource.dart
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   └── local/            # Cache local / SQLite
│   │   │       ├── stock_local_datasource.dart
│   │   │       ├── document_local_datasource.dart
│   │   │       └── preferences_datasource.dart
│   │   ├── models/               # Modelos de dados (DTOs)
│   │   │   ├── stock_item_model.dart
│   │   │   ├── document_model.dart
│   │   │   ├── customer_model.dart
│   │   │   ├── supplier_model.dart
│   │   │   └── auth_model.dart
│   │   └── repositories/         # Implementação dos repositórios
│   │       ├── stock_repository_impl.dart
│   │       ├── document_repository_impl.dart
│   │       ├── customer_repository_impl.dart
│   │       ├── supplier_repository_impl.dart
│   │       └── auth_repository_impl.dart
│   └── presentation/              # Camada de Apresentação (UI)
│       ├── state_management/      # Gerenciamento de estado
│       │   ├── blocs/            # BLoC pattern (alternativa ao Provider)
│       │   │   ├── stock/
│       │   │   ├── documents/
│       │   │   ├── customers/
│       │   │   ├── suppliers/
│       │   │   └── auth/
│       │   └── providers/        # Providers atuais (manter compatibilidade)
│       │       ├── stock_provider.dart
│       │       ├── document_provider.dart
│       │       └── auth_provider.dart
│       ├── pages/                # Páginas da aplicação
│       │   ├── stock/
│       │   │   ├── stock_list_page.dart
│       │   │   ├── stock_detail_page.dart
│       │   │   └── add_stock_page.dart
│       │   ├── documents/
│       │   │   ├── documents_list_page.dart
│       │   │   ├── document_detail_page.dart
│       │   │   ├── balance_sheet_page.dart
│       │   │   └── add_document_page.dart
│       │   ├── customers/
│       │   ├── suppliers/
│       │   ├── stores/
│       │   └── auth/
│       └── widgets/              # Widgets reutilizáveis
│           ├── common/           # Widgets comuns
│           │   ├── app_drawer.dart
│           │   ├── loading_widget.dart
│           │   ├── error_widget.dart
│           │   └── custom_button.dart
│           ├── stock/            # Widgets específicos do estoque
│           │   ├── stock_item_card.dart
│           │   └── stock_filter_widget.dart
│           └── documents/        # Widgets específicos dos documentos
│               ├── document_card.dart
│               ├── balance_sheet_widget.dart
│               └── document_form_widget.dart
├── shared/                       # Código compartilhado
│   ├── constants/               # Constantes da aplicação
│   │   ├── app_constants.dart
│   │   ├── api_constants.dart
│   │   └── ui_constants.dart
│   ├── extensions/              # Extensões úteis
│   │   ├── date_extensions.dart
│   │   ├── string_extensions.dart
│   │   └── number_extensions.dart
│   ├── utils/                   # Utilitários
│   │   ├── validators.dart
│   │   ├── formatters.dart
│   │   ├── error_handler.dart
│   │   └── app_router.dart
│   └── services/               # Serviços transversais
│       ├── notification_service.dart
│       ├── pdf_service.dart
│       ├── csv_service.dart
│       └── storage_service.dart
└── config/                     # Configurações
    ├── app_config.dart
    ├── theme_config.dart
    ├── di_config.dart          # Dependency Injection
    └── router_config.dart

# Arquivos antigos (manter para migração gradual)
models/                         # DEPRECATED - mover para core/data/models
providers/                      # DEPRECATED - mover para core/presentation/state_management/providers
screens/                        # DEPRECATED - mover para core/presentation/pages
services/                       # DEPRECATED - mover para core/data/datasources ou shared/services
utils/                         # DEPRECATED - mover para shared/utils
widgets/                       # DEPRECATED - mover para core/presentation/widgets
