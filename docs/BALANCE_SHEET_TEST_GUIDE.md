# Guia de Teste: Nova Funcionalidade de Balancete e Exportação CSV

## 🎯 Objetivo dos Testes

Validar a nova funcionalidade de balancete na aba "BALANÇA" e a exportação contextual de relatórios CSV.

## 🚀 Como Testar

### Pré-requisitos
1. Backend rodando em `http://localhost:3000`
2. Frontend rodando em `http://localhost:8080`
3. Usuário logado no sistema
4. Loja selecionada

### Passo 1: Acesso à Funcionalidade
1. Faça login na aplicação
2. Selecione uma loja
3. Navegue para "Documentos" no menu lateral
4. Clique na aba "BALANÇA"

### Passo 2: Testando o Balancete

#### 2.1 Visualização do Resumo
- ✅ Verifique se os cards de resumo são exibidos:
  - **Card Verde**: Total de Entradas + quantidade de documentos
  - **Card Vermelho**: Total de Saídas + quantidade de documentos  
  - **Card Azul/Laranja**: Saldo Líquido (positivo=azul, negativo=laranja)

#### 2.2 Filtros de Período
- ✅ Teste o dropdown de período:
  - **Hoje**: Mostra apenas documentos de hoje
  - **Esta Semana**: Documentos da semana atual
  - **Este Mês**: Documentos do mês atual
  - **Todos os Períodos**: Sem filtro temporal

#### 2.3 Detalhamento por Tabs
- ✅ **Aba "Entradas"**: 
  - Lista documentos do tipo `entrada` e `ajuste_entrada`
  - Cada item mostra: número, descrição, data, quantidade de itens, valor
  - Ícones verdes
- ✅ **Aba "Saídas"**:
  - Lista documentos do tipo `saida` e `ajuste_saida` 
  - Cada item mostra: número, descrição, data, quantidade de itens, valor
  - Ícones vermelhos

### Passo 3: Testando Exportação CSV

#### 3.1 Exportação da Aba BALANÇA
1. Estando na aba "BALANÇA"
2. Clique no ícone de download (📥) no período ou na barra superior
3. ✅ Verifique a mensagem de sucesso com:
   - Tipo: "Balancete"
   - Nome do arquivo: `balancete_YYYYMMDD_HHMMSS.csv`
   - Quantidade de registros
   - Tamanho em caracteres

#### 3.2 Exportação de Outras Abas
1. Navegue para aba "TODOS"
2. Clique no ícone de download
3. ✅ Mensagem deve indicar "Todos os Documentos"

4. Navegue para aba "ENTRADA"  
5. Clique no ícone de download
6. ✅ Mensagem deve indicar "Documentos - ENTRADA"

7. Navegue para aba "SAÍDA"
8. Clique no ícone de download  
9. ✅ Mensagem deve indicar "Documentos - SAÍDA"

### Passo 4: Validação de Cálculos

#### 4.1 Teste com Documentos Existentes
Se houver documentos no sistema:
- ✅ Soma das entradas = valor mostrado no card verde
- ✅ Soma das saídas = valor mostrado no card vermelho  
- ✅ Saldo líquido = entradas - saídas

#### 4.2 Teste Criando Novos Documentos
1. Crie um documento de entrada:
   - Vá em "+" → Novo Documento
   - Tipo: "Entrada" 
   - Adicione itens com quantidade e preço
   - Salve o documento

2. ✅ Volte para aba "BALANÇA" e verifique:
   - Card de entradas aumentou
   - Documento aparece na aba "Entradas"
   - Saldo líquido foi recalculado

3. Crie um documento de saída:
   - Tipo: "Saída"
   - Adicione itens
   - Salve o documento

4. ✅ Verifique:
   - Card de saídas aumentou
   - Documento aparece na aba "Saídas"  
   - Saldo líquido foi recalculado

## 🧪 Cenários de Teste Específicos

### Cenário 1: Sistema Sem Documentos
- ✅ Cards mostram R$ 0,00
- ✅ Abas mostram "Nenhum documento encontrado"
- ✅ Exportação mostra mensagem apropriada

### Cenário 2: Apenas Entradas
- ✅ Card verde > 0, card vermelho = 0
- ✅ Saldo líquido = valor das entradas (positivo, azul)
- ✅ Aba "Saídas" vazia

### Cenário 3: Apenas Saídas  
- ✅ Card verde = 0, card vermelho > 0
- ✅ Saldo líquido = valor negativo das saídas (laranja)
- ✅ Aba "Entradas" vazia

### Cenário 4: Entradas e Saídas Equilibradas
- ✅ Ambos os cards > 0
- ✅ Saldo líquido próximo de 0
- ✅ Ambas as abas com conteúdo

### Cenário 5: Filtros de Período
- ✅ Alterar período atualiza todos os valores automaticamente
- ✅ Documentos fora do período não aparecem
- ✅ Contadores e totais são recalculados

## 🔍 Pontos de Atenção

### Interface
- [ ] Cards responsivos em diferentes tamanhos de tela
- [ ] Cores consistentes (verde=entradas, vermelho=saídas, azul/laranja=saldo)
- [ ] Ícones apropriados para cada tipo de documento
- [ ] Formatação monetária brasileira (R$ 1.234,56)
- [ ] Formatação de data brasileira (dd/MM/yyyy)

### Funcionalidade  
- [ ] Cálculos matemáticos corretos
- [ ] Filtros de período funcionando
- [ ] Atualização automática ao mudar período
- [ ] Mensagens de erro apropriadas
- [ ] Performance adequada com muitos documentos

### Exportação CSV
- [ ] Conteúdo do arquivo reflete o contexto atual
- [ ] Metadados informativos no cabeçalho
- [ ] Formatação brasileira mantida
- [ ] Nomes de arquivo descritivos e únicos
- [ ] Tratamento de caracteres especiais

## 🐛 Problemas Conhecidos

### Limitações Atuais
1. **Download Real**: Atualmente simula o download, mostra apenas confirmação
2. **Dados de Teste**: Requer documentos existentes para teste completo
3. **Validação de Dados**: Documentos com datas inválidas são ignorados

### Soluções Futuras
1. Implementar download real de arquivos
2. Adicionar dados de demonstração
3. Melhorar tratamento de erros de data

## ✅ Critérios de Aceitação

A funcionalidade estará aprovada quando:

1. **Visualização**: ✅
   - Cards de resumo corretos e coloridos
   - Filtros de período funcionais
   - Abas de detalhamento operacionais

2. **Cálculos**: ✅  
   - Somas corretas de entradas e saídas
   - Saldo líquido preciso
   - Atualização automática

3. **Exportação**: ✅
   - Contexto correto baseado na aba atual
   - Formatos de arquivo apropriados
   - Mensagens informativas

4. **Usabilidade**: ✅
   - Interface intuitiva
   - Feedback visual claro
   - Navegação fluida

## 📞 Suporte

Em caso de problemas:
1. Verifique se backend e frontend estão rodando
2. Confirme se há dados de teste suficientes
3. Verifique o console do navegador para erros
4. Teste em modo debug para mais informações
