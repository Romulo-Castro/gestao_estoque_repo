# Gestão de Estoques PRO

Um sistema completo de gestão de estoques com arquitetura cliente-servidor:
- **Backend**: Node.js + Express + SQLite (API RESTful)
- **Frontend**: Flutter (Mobile) com Provider para gerenciamento de estado

---

## Índice
1. [Visão Geral](#visão-geral)
2. [Requisitos](#requisitos)
3. [Arquitetura e Estrutura](#arquitetura-e-estrutura)
4. [Configuração](#configuração)
   - [Backend](#backend)
   - [Frontend](#frontend)
5. [Executando o Projeto](#executando-o-projeto)
   - [Rodando o Backend](#rodando-o-backend)
   - [Rodando o Frontend](#rodando-o-frontend)
6. [Documentação](#documentação)
7. [Testes e Qualidade de Código](#testes-e-qualidade-de-código)
8. [Roadmap / Futuras Melhorias](#roadmap--futuras-melhorias)
9. [Licença](#licença)

---

## Visão Geral
O sistema permite ao usuário:
- Autenticação com JWT
- Gerenciar múltiplas lojas
- CRUD de grupos de itens, itens de estoque, clientes, fornecedores e documentos de movimentação (entrada/saída)
- Configurar preferências iniciais no app móvel

## Requisitos
- **Node.js** >= 18.x
- **Flutter** >= 3.0
- **Dart SDK** compatible com Flutter
- **SQLite** (vem embutido no backend)
- **Powershell** (Windows)

## Arquitetura e Estrutura
```
/gestao_estoque_repo
├── backend/           # API RESTful em Node.js + Express
│   ├── src/
│   │   ├── controllers/
│   │   ├── routes/
│   │   ├── middleware/
│   │   └── data/
│   ├── uploads/       # Arquivos enviados pelo Multer
│   └── inventory_data.db
└── frontend/          # App Flutter
    ├── lib/
    │   ├── models/
    │   ├── providers/
    │   ├── screens/
    │   ├── services/
    │   └── widgets/
    └── pubspec.yaml
```

## Configuração
### Backend
1. Abra um terminal no diretório `backend/`
2. Instale dependências:
   ```powershell
   npm install
   ```
3. Crie um arquivo `.env` com as variáveis:
   ```env
   PORT=3000
   JWT_SECRET=sua_chave_secreta
   SQLITE_PATH=./inventory_data.db
   UPLOAD_FOLDER=uploads
   ```

### Frontend
1. Abra um terminal no diretório `frontend/`
2. Instale as dependências do Flutter:
   ```powershell
   flutter pub get
   ```

## Executando o Projeto
### Rodando o Backend
```powershell
cd backend
npm run start
```
A API ficará disponível em `http://localhost:3000/api`.

### Rodando o Frontend
```powershell
cd frontend
flutter run
```
No emulador/dispositivo, o app iniciará e usará `http://10.0.2.2:3000/api` para conectar no backend.

## Documentação
- Veja `DOCUMENTATION.md` para detalhes das rotas e payloads.
- `todo.md` lista melhorias pendentes.

## Testes e Qualidade de Código
- **Backend**: inclua testes unitários em `src/tests/`
- **Frontend**: utilize `flutter test` para rodar testes de unidade e widget.

## Roadmap / Futuras Melhorias
- Validadores mais robustos com `express-validator` e formulários Flutter
- Migração para banco de produção (PostgreSQL/MySQL)
- Suporte offline no app com sincronização
- Melhorias de UI/UX

## Licença
MIT © 2025
