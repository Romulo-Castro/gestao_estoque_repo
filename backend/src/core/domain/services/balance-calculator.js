// core/domain/services/balance-calculator.js

const DateRange = require('../value-objects/date-range');
const Money = require('../value-objects/money');

/**
 * Serviço de Domínio - Calculadora de Balanço
 * Responsável por calcular balanços financeiros e de estoque
 */
class BalanceCalculator {
  constructor(documentRepository) {
    this.documentRepository = documentRepository;
  }

  /**
   * Calcula o balanço financeiro para um período
   * @param {DateRange} dateRange - Período para cálculo
   * @param {number} storeId - ID da loja
   * @returns {Promise<Object>} Objeto com o balanço calculado
   */
  async calculateFinancialBalance(dateRange, storeId) {
    try {
      // Buscar documentos do período
      const documents = await this.documentRepository.findByDateRange(
        dateRange.startDate,
        dateRange.endDate,
        storeId
      );

      // Filtrar apenas documentos ativos
      const activeDocuments = documents.filter(doc => doc.status === 'ATIVO');

      // Separar entradas e saídas
      const inflows = activeDocuments.filter(doc => doc.type === 'ENTRADA');
      const outflows = activeDocuments.filter(doc => doc.type === 'SAÍDA');

      // Calcular totais
      const totalInflows = new Money(
        inflows.reduce((sum, doc) => sum + (doc.totalValue || 0), 0)
      );

      const totalOutflows = new Money(
        outflows.reduce((sum, doc) => sum + (doc.totalValue || 0), 0)
      );

      // Calcular balanço líquido
      const netBalance = totalInflows.subtract(totalOutflows);

      return {
        period: dateRange.toString(),
        totalInflows: totalInflows.getValue(),
        totalOutflows: totalOutflows.getValue(),
        netBalance: netBalance.getValue(),
        inflowCount: inflows.length,
        outflowCount: outflows.length,
        totalDocuments: activeDocuments.length,
        inflows: inflows.map(doc => ({
          id: doc.id,
          number: doc.number,
          date: doc.date,
          value: doc.totalValue,
          description: doc.description
        })),
        outflows: outflows.map(doc => ({
          id: doc.id,
          number: doc.number,
          date: doc.date,
          value: doc.totalValue,
          description: doc.description
        }))
      };
    } catch (error) {
      throw new Error(`Erro ao calcular balanço financeiro: ${error.message}`);
    }
  }

  /**
   * Calcula balanço por tipo de documento
   * @param {string} documentType - Tipo do documento
   * @param {DateRange} dateRange - Período para cálculo
   * @param {number} storeId - ID da loja
   * @returns {Promise<Object>}
   */
  async calculateBalanceByType(documentType, dateRange, storeId) {
    try {
      const documents = await this.documentRepository.findByDateRange(
        dateRange.startDate,
        dateRange.endDate,
        storeId
      );

      const filteredDocuments = documents.filter(doc => 
        doc.type === documentType && doc.status === 'ATIVO'
      );

      const totalValue = new Money(
        filteredDocuments.reduce((sum, doc) => sum + (doc.totalValue || 0), 0)
      );

      return {
        type: documentType,
        period: dateRange.toString(),
        totalValue: totalValue.getValue(),
        documentCount: filteredDocuments.length,
        documents: filteredDocuments.map(doc => ({
          id: doc.id,
          number: doc.number,
          date: doc.date,
          value: doc.totalValue,
          description: doc.description
        }))
      };
    } catch (error) {
      throw new Error(`Erro ao calcular balanço por tipo: ${error.message}`);
    }
  }

  /**
   * Calcula resumo mensal
   * @param {number} year - Ano
   * @param {number} month - Mês (1-12)
   * @param {number} storeId - ID da loja
   * @returns {Promise<Object>}
   */
  async calculateMonthlyBalance(year, month, storeId) {
    try {
      const startDate = new Date(year, month - 1, 1);
      const endDate = new Date(year, month, 0);
      const dateRange = new DateRange(startDate, endDate);

      return await this.calculateFinancialBalance(dateRange, storeId);
    } catch (error) {
      throw new Error(`Erro ao calcular balanço mensal: ${error.message}`);
    }
  }

  /**
   * Calcula resumo anual
   * @param {number} year - Ano
   * @param {number} storeId - ID da loja
   * @returns {Promise<Object>}
   */
  async calculateYearlyBalance(year, storeId) {
    try {
      const startDate = new Date(year, 0, 1);
      const endDate = new Date(year, 11, 31);
      const dateRange = new DateRange(startDate, endDate);

      return await this.calculateFinancialBalance(dateRange, storeId);
    } catch (error) {
      throw new Error(`Erro ao calcular balanço anual: ${error.message}`);
    }
  }

  /**
   * Calcula tendência de crescimento
   * @param {DateRange} currentPeriod - Período atual
   * @param {DateRange} previousPeriod - Período anterior
   * @param {number} storeId - ID da loja
   * @returns {Promise<Object>}
   */
  async calculateGrowthTrend(currentPeriod, previousPeriod, storeId) {
    try {
      const currentBalance = await this.calculateFinancialBalance(currentPeriod, storeId);
      const previousBalance = await this.calculateFinancialBalance(previousPeriod, storeId);

      const inflowGrowth = this._calculatePercentageGrowth(
        previousBalance.totalInflows,
        currentBalance.totalInflows
      );

      const outflowGrowth = this._calculatePercentageGrowth(
        previousBalance.totalOutflows,
        currentBalance.totalOutflows
      );

      const netBalanceGrowth = this._calculatePercentageGrowth(
        previousBalance.netBalance,
        currentBalance.netBalance
      );

      return {
        currentPeriod: currentBalance,
        previousPeriod: previousBalance,
        growth: {
          inflows: inflowGrowth,
          outflows: outflowGrowth,
          netBalance: netBalanceGrowth
        }
      };
    } catch (error) {
      throw new Error(`Erro ao calcular tendência de crescimento: ${error.message}`);
    }
  }

  /**
   * Calcula percentual de crescimento
   * @private
   */
  _calculatePercentageGrowth(previousValue, currentValue) {
    if (previousValue === 0) {
      return currentValue > 0 ? 100 : 0;
    }
    return ((currentValue - previousValue) / previousValue) * 100;
  }
}

module.exports = BalanceCalculator;
