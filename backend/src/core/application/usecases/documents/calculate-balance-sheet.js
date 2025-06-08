// core/application/usecases/documents/calculate-balance-sheet.js

const BalanceCalculator = require('../../../domain/services/balance-calculator');
const DateRange = require('../../../domain/value-objects/date-range');

/**
 * Caso de Uso - Calcular Balanço Patrimonial
 * Responsável por calcular diferentes tipos de balanços
 */
class CalculateBalanceSheet {
  constructor(documentRepository) {
    this.documentRepository = documentRepository;
    this.balanceCalculator = new BalanceCalculator(documentRepository);
  }

  /**
   * Executa o caso de uso
   * @param {Object} params - Parâmetros do cálculo
   * @param {number} params.storeId - ID da loja
   * @param {string} params.period - Tipo de período ('custom', 'month', 'year', 'lastDays')
   * @param {Date} [params.startDate] - Data inicial (para período customizado)
   * @param {Date} [params.endDate] - Data final (para período customizado)
   * @param {number} [params.year] - Ano (para período anual)
   * @param {number} [params.month] - Mês (para período mensal)
   * @param {number} [params.days] - Número de dias (para últimos dias)
   * @param {boolean} [params.includeComparison] - Se deve incluir comparação com período anterior
   * @returns {Promise<Object>} Balanço calculado
   */
  async execute(params) {
    try {
      // Validações
      if (!params.storeId) {
        throw new Error('Store ID é obrigatório');
      }

      if (!params.period) {
        throw new Error('Tipo de período é obrigatório');
      }

      // Determinar período baseado no tipo
      let dateRange;
      let previousDateRange;

      switch (params.period) {
        case 'custom':
          if (!params.startDate || !params.endDate) {
            throw new Error('Datas inicial e final são obrigatórias para período customizado');
          }
          dateRange = new DateRange(params.startDate, params.endDate);
          break;

        case 'month':
          if (!params.year || !params.month) {
            throw new Error('Ano e mês são obrigatórios para período mensal');
          }
          const monthStart = new Date(params.year, params.month - 1, 1);
          const monthEnd = new Date(params.year, params.month, 0);
          dateRange = new DateRange(monthStart, monthEnd);
          
          // Período anterior (mês anterior)
          if (params.includeComparison) {
            const prevMonth = params.month === 1 ? 12 : params.month - 1;
            const prevYear = params.month === 1 ? params.year - 1 : params.year;
            const prevMonthStart = new Date(prevYear, prevMonth - 1, 1);
            const prevMonthEnd = new Date(prevYear, prevMonth, 0);
            previousDateRange = new DateRange(prevMonthStart, prevMonthEnd);
          }
          break;

        case 'year':
          if (!params.year) {
            throw new Error('Ano é obrigatório para período anual');
          }
          const yearStart = new Date(params.year, 0, 1);
          const yearEnd = new Date(params.year, 11, 31);
          dateRange = new DateRange(yearStart, yearEnd);
          
          // Período anterior (ano anterior)
          if (params.includeComparison) {
            const prevYearStart = new Date(params.year - 1, 0, 1);
            const prevYearEnd = new Date(params.year - 1, 11, 31);
            previousDateRange = new DateRange(prevYearStart, prevYearEnd);
          }
          break;

        case 'lastDays':
          if (!params.days || params.days <= 0) {
            throw new Error('Número de dias deve ser positivo');
          }
          dateRange = DateRange.lastDays(params.days);
          
          // Período anterior (mesmo número de dias, mas anteriores)
          if (params.includeComparison) {
            const endDate = new Date();
            endDate.setDate(endDate.getDate() - params.days);
            const startDate = new Date(endDate);
            startDate.setDate(startDate.getDate() - params.days + 1);
            previousDateRange = new DateRange(startDate, endDate);
          }
          break;

        default:
          throw new Error(`Tipo de período inválido: ${params.period}`);
      }

      // Calcular balanço principal
      const balance = await this.balanceCalculator.calculateFinancialBalance(
        dateRange, 
        params.storeId
      );

      const result = {
        balance,
        period: {
          type: params.period,
          range: dateRange.toString()
        }
      };

      // Incluir comparação se solicitado
      if (params.includeComparison && previousDateRange) {
        const growthTrend = await this.balanceCalculator.calculateGrowthTrend(
          dateRange,
          previousDateRange,
          params.storeId
        );
        result.comparison = growthTrend;
      }

      // Calcular balanços por tipo
      const typeBalances = await Promise.all([
        this.balanceCalculator.calculateBalanceByType('ENTRADA', dateRange, params.storeId),
        this.balanceCalculator.calculateBalanceByType('SAÍDA', dateRange, params.storeId),
        this.balanceCalculator.calculateBalanceByType('BALANÇA', dateRange, params.storeId)
      ]);

      result.balancesByType = {
        'ENTRADA': typeBalances[0],
        'SAÍDA': typeBalances[1],
        'BALANÇA': typeBalances[2]
      };

      return result;

    } catch (error) {
      throw new Error(`Erro ao calcular balanço: ${error.message}`);
    }
  }

  /**
   * Calcula balanço simples para um período
   * @param {Date} startDate - Data inicial
   * @param {Date} endDate - Data final
   * @param {number} storeId - ID da loja
   * @returns {Promise<Object>}
   */
  async calculateSimpleBalance(startDate, endDate, storeId) {
    try {
      const dateRange = new DateRange(startDate, endDate);
      return await this.balanceCalculator.calculateFinancialBalance(dateRange, storeId);
    } catch (error) {
      throw new Error(`Erro ao calcular balanço simples: ${error.message}`);
    }
  }
}

module.exports = CalculateBalanceSheet;
