# Documentação do Projeto: Gestão de Estoques

## Visão Geral

O sistema de Gestão de Estoques é uma aplicação completa para gerenciamento de inventário, clientes, fornecedores e documentos de entrada/saída. Desenvolvido com Flutter (frontend) e Node.js (backend), o sistema permite o controle eficiente de múltiplas lojas, com recursos avançados de categorização, relatórios e configurações personalizáveis.

## Arquitetura

### Frontend (Flutter)
- **Linguagem**: Dart
- **Framework**: Flutter
- **Gerenciamento de Estado**: Provider
- **Armazenamento Local**: SharedPreferences
- **Comunicação com Backend**: HTTP REST API

### Backend (Node.js)
- **Linguagem**: JavaScript
- **Framework**: Express.js
- **Banco de Dados**: SQLite (facilmente substituível por MySQL/PostgreSQL)
- **Autenticação**: JWT (JSON Web Tokens)
- **Upload de Arquivos**: Multer

## Funcionalidades Principais

### Autenticação e Usuários
- Login e registro de usuários
- Autenticação via token JWT
- Persistência de sessão
- Logout seguro

### Gerenciamento de Lojas
- Criação, edição e exclusão de lojas
- Seleção de loja ativa
- Associação de usuários a lojas

### Controle de Estoque
- Cadastro completo de itens com propriedades customizáveis
- Upload de imagens para itens
- Controle de quantidade e preços
- Categorização por grupos

### Grupos de Itens
- Organização hierárquica de produtos
- Atribuição de propriedades por grupo
- Filtros e buscas por categoria

### Clientes e Fornecedores
- Cadastro completo com informações de contato
- Histórico de transações
- Associação com documentos

### Documentos (Entrada/Saída/Ajuste)
- Registro de movimentações de estoque
- Notas de entrada (compras)
- Notas de saída (vendas)
- Ajustes de inventário
- Vinculação com clientes/fornecedores

### Relatórios
- Visão geral do estoque
- Análise de vendas
- Relatórios financeiros
- Produtos com estoque baixo

### Configurações
- Personalização da interface
- Preferências de usuário
- Configurações de notificações
- Gerenciamento de perfil

## Estrutura do Projeto

### Frontend

```
frontend/
├── lib/
│   ├── main.dart                  # Ponto de entrada da aplicação
│   ├── models/                    # Modelos de dados
│   │   ├── stock_item.dart        # Modelo de item de estoque
│   │   ├── store_model.dart       # Modelo de loja
│   │   ├── customer_model.dart    # Modelo de cliente
│   │   ├── supplier_model.dart    # Modelo de fornecedor
│   │   ├── item_group_model.dart  # Modelo de grupo de itens
│   │   ├── document_model.dart    # Modelo de documento
│   │   └── document_item_model.dart # Modelo de item de documento
│   ├── providers/                 # Gerenciadores de estado
│   │   ├── auth_provider.dart     # Gerencia autenticação
│   │   ├── store_provider.dart    # Gerencia lojas
│   │   ├── stock_provider.dart    # Gerencia itens de estoque
│   │   ├── item_group_provider.dart # Gerencia grupos de itens
│   │   ├── customer_provider.dart # Gerencia clientes
│   │   ├── supplier_provider.dart # Gerencia fornecedores
│   │   └── document_provider.dart # Gerencia documentos
│   ├── screens/                   # Telas da aplicação
│   │   ├── login_screen.dart      # Tela de login
│   │   ├── register_screen.dart   # Tela de registro
│   │   ├── home_screen.dart       # Tela inicial/dashboard
│   │   ├── stock_screen.dart      # Lista de itens de estoque
│   │   ├── edit_stock_item_screen.dart # Edição de item de estoque
│   │   ├── store_management_screen.dart # Gerenciamento de lojas
│   │   ├── item_group_list_screen.dart # Lista de grupos de itens
│   │   ├── edit_item_group_screen.dart # Edição de grupo de itens
│   │   ├── customer_list_screen.dart # Lista de clientes
│   │   ├── edit_customer_screen.dart # Edição de cliente
│   │   ├── supplier_list_screen.dart # Lista de fornecedores
│   │   ├── edit_supplier_screen.dart # Edição de fornecedor
│   │   ├── document_list_screen.dart # Lista de documentos
│   │   ├── edit_document_screen.dart # Edição de documento
│   │   ├── document_detail_screen.dart # Detalhes de documento
│   │   ├── reports_screen.dart    # Relatórios
│   │   └── settings_screen.dart   # Configurações
│   ├── services/                  # Serviços
│   │   └── api_service.dart       # Comunicação com a API
│   ├── utils/                     # Utilitários
│   │   └── app_prefs.dart         # Preferências do aplicativo
│   └── widgets/                   # Widgets reutilizáveis
│       └── app_drawer.dart        # Menu lateral
```

### Backend

```
backend/
├── src/
│   ├── server.js                  # Configuração do servidor
│   ├── data/
│   │   └── database.js            # Conexão com banco de dados
│   ├── controllers/
│   │   ├── authController.js      # Controlador de autenticação
│   │   ├── stockController.js     # Controlador de estoque
│   │   ├── storeController.js     # Controlador de lojas
│   │   ├── itemGroupController.js # Controlador de grupos de itens
│   │   ├── customerController.js  # Controlador de clientes
│   │   ├── supplierController.js  # Controlador de fornecedores
│   │   └── documentController.js  # Controlador de documentos
│   ├── routes/
│   │   ├── authRoutes.js          # Rotas de autenticação
│   │   ├── stockRoutes.js         # Rotas de estoque
│   │   ├── storeRoutes.js         # Rotas de lojas
│   │   ├── itemGroupRoutes.js     # Rotas de grupos de itens
│   │   ├── customerRoutes.js      # Rotas de clientes
│   │   ├── supplierRoutes.js      # Rotas de fornecedores
│   │   └── documentRoutes.js      # Rotas de documentos
│   └── middleware/
│       ├── authMiddleware.js      # Middleware de autenticação
│       ├── uploadMiddleware.js    # Middleware de upload
│       └── validators.js          # Validadores de dados
```

## Configuração e Execução

### Backend

1. Navegue até a pasta `backend`
2. Instale as dependências:
   ```
   npm install
   ```
3. Configure o arquivo `.env` com as variáveis de ambiente necessárias:
   ```
   PORT=3000
   JWT_SECRET=sua_chave_secreta_aqui
   DB_PATH=./data/database.sqlite
   ```
4. Inicie o servidor:
   ```
   npm run dev
   ```

### Frontend

1. Navegue até a pasta `frontend`
2. Instale as dependências:
   ```
   flutter pub get
   ```
3. Execute o aplicativo:
   ```
   flutter run
   ```

## Fluxos Principais

### Autenticação

1. O usuário acessa a tela de login
2. Insere email e senha
3. O sistema valida as credenciais com o backend
4. Em caso de sucesso, armazena o token JWT e dados do usuário
5. Redireciona para a tela inicial ou de seleção de loja

### Seleção de Loja

1. Após o login, o usuário é direcionado para a tela inicial
2. Se não houver lojas, é apresentada a opção de criar uma nova
3. Se houver lojas, o usuário pode selecionar uma existente
4. A loja selecionada é armazenada nas preferências do aplicativo
5. Todas as operações subsequentes são contextualizadas para a loja selecionada

### Gerenciamento de Estoque

1. O usuário acessa a tela de estoque
2. Visualiza a lista de itens cadastrados
3. Pode adicionar, editar ou excluir itens
4. Ao editar um item, pode atualizar propriedades, preços, quantidades e imagem
5. Os itens podem ser categorizados por grupos

### Documentos de Entrada/Saída

1. O usuário acessa a tela de documentos
2. Cria um novo documento (entrada, saída ou ajuste)
3. Seleciona cliente ou fornecedor (quando aplicável)
4. Adiciona itens ao documento, especificando quantidades e preços
5. Finaliza o documento, que atualiza automaticamente o estoque

### Relatórios

1. O usuário acessa a tela de relatórios
2. Seleciona o tipo de relatório desejado (Estoque, Vendas, Financeiro)
3. Visualiza os dados consolidados e análises
4. Pode filtrar por período ou outras propriedades relevantes

## Melhorias Implementadas

1. **Correção do fluxo de autenticação**:
   - Implementação de logs detalhados para depuração
   - Tratamento adequado de erros e feedback ao usuário
   - Persistência segura de token e dados de usuário

2. **Correção da seleção de lojas**:
   - Fluxo aprimorado após o login
   - Opção de criar loja quando não há nenhuma disponível
   - Persistência da seleção entre sessões

3. **Implementação de novas funcionalidades**:
   - Tela de relatórios com três categorias (Estoque, Vendas, Financeiro)
   - Tela de configurações com opções de personalização
   - Sistema de filtros para documentos

4. **Melhorias de interface**:
   - Menu lateral consistente em todas as telas
   - Feedback visual para operações (loading, mensagens)
   - Navegação intuitiva entre telas relacionadas

5. **Correções técnicas**:
   - Implementação de métodos faltantes no ApiService
   - Correção de modelos de dados
   - Padronização de providers
   - Tratamento adequado de valores nulos

## Próximos Passos Sugeridos

1. **Implementação de testes automatizados**:
   - Testes unitários para lógica de negócio
   - Testes de integração para fluxos completos
   - Testes de interface para validar experiência do usuário

2. **Melhorias de desempenho**:
   - Implementação de cache para dados frequentemente acessados
   - Otimização de consultas ao backend
   - Carregamento lazy de imagens e dados pesados

3. **Recursos avançados**:
   - Integração com leitor de código de barras
   - Sincronização offline
   - Exportação de relatórios em PDF/Excel
   - Notificações push para alertas de estoque baixo

4. **Segurança**:
   - Implementação de autenticação em dois fatores
   - Criptografia de dados sensíveis
   - Auditoria de operações críticas

## Suporte e Contato

Para suporte técnico ou dúvidas sobre o sistema, entre em contato através dos canais disponibilizados pela equipe de desenvolvimento.
