// Date Utilities
class DateUtils {
    static now() {
        return new Date();
    }

    static startOfDay(date = new Date()) {
        const result = new Date(date);
        result.setHours(0, 0, 0, 0);
        return result;
    }

    static endOfDay(date = new Date()) {
        const result = new Date(date);
        result.setHours(23, 59, 59, 999);
        return result;
    }

    static startOfWeek(date = new Date()) {
        const result = new Date(date);
        const day = result.getDay();
        const diff = result.getDate() - day + (day === 0 ? -6 : 1); // Monday as first day
        result.setDate(diff);
        return this.startOfDay(result);
    }

    static endOfWeek(date = new Date()) {
        const result = this.startOfWeek(date);
        result.setDate(result.getDate() + 6);
        return this.endOfDay(result);
    }

    static startOfMonth(date = new Date()) {
        const result = new Date(date);
        result.setDate(1);
        return this.startOfDay(result);
    }

    static endOfMonth(date = new Date()) {
        const result = new Date(date);
        result.setMonth(result.getMonth() + 1, 0);
        return this.endOfDay(result);
    }

    static startOfQuarter(date = new Date()) {
        const result = new Date(date);
        const quarter = Math.floor(result.getMonth() / 3);
        result.setMonth(quarter * 3, 1);
        return this.startOfDay(result);
    }

    static endOfQuarter(date = new Date()) {
        const result = this.startOfQuarter(date);
        result.setMonth(result.getMonth() + 3, 0);
        return this.endOfDay(result);
    }

    static startOfYear(date = new Date()) {
        const result = new Date(date);
        result.setMonth(0, 1);
        return this.startOfDay(result);
    }

    static endOfYear(date = new Date()) {
        const result = new Date(date);
        result.setMonth(11, 31);
        return this.endOfDay(result);
    }

    static addDays(date, days) {
        const result = new Date(date);
        result.setDate(result.getDate() + days);
        return result;
    }

    static addMonths(date, months) {
        const result = new Date(date);
        result.setMonth(result.getMonth() + months);
        return result;
    }

    static addYears(date, years) {
        const result = new Date(date);
        result.setFullYear(result.getFullYear() + years);
        return result;
    }

    static subtractDays(date, days) {
        return this.addDays(date, -days);
    }

    static subtractMonths(date, months) {
        return this.addMonths(date, -months);
    }

    static subtractYears(date, years) {
        return this.addYears(date, -years);
    }

    static daysBetween(startDate, endDate) {
        const diffTime = Math.abs(endDate - startDate);
        return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    }

    static monthsBetween(startDate, endDate) {
        const years = endDate.getFullYear() - startDate.getFullYear();
        const months = endDate.getMonth() - startDate.getMonth();
        return years * 12 + months;
    }

    static formatToBR(date) {
        return date.toLocaleDateString('pt-BR');
    }

    static formatToISO(date) {
        return date.toISOString();
    }

    static formatToSQL(date) {
        return date.toISOString().slice(0, 19).replace('T', ' ');
    }

    static isValidDate(date) {
        return date instanceof Date && !isNaN(date.getTime());
    }

    static parseDate(dateString) {
        const date = new Date(dateString);
        return this.isValidDate(date) ? date : null;
    }

    static today() {
        return this.startOfDay();
    }

    static yesterday() {
        return this.startOfDay(this.subtractDays(new Date(), 1));
    }

    static tomorrow() {
        return this.startOfDay(this.addDays(new Date(), 1));
    }

    static thisWeek() {
        return {
            start: this.startOfWeek(),
            end: this.endOfWeek()
        };
    }

    static lastWeek() {
        const lastWeekDate = this.subtractDays(new Date(), 7);
        return {
            start: this.startOfWeek(lastWeekDate),
            end: this.endOfWeek(lastWeekDate)
        };
    }

    static thisMonth() {
        return {
            start: this.startOfMonth(),
            end: this.endOfMonth()
        };
    }

    static lastMonth() {
        const lastMonthDate = this.subtractMonths(new Date(), 1);
        return {
            start: this.startOfMonth(lastMonthDate),
            end: this.endOfMonth(lastMonthDate)
        };
    }

    static thisYear() {
        return {
            start: this.startOfYear(),
            end: this.endOfYear()
        };
    }

    static lastYear() {
        const lastYearDate = this.subtractYears(new Date(), 1);
        return {
            start: this.startOfYear(lastYearDate),
            end: this.endOfYear(lastYearDate)
        };
    }
}

module.exports = { DateUtils };
