import Chart from 'chart.js/auto';

const ChartHook = {
  mounted() {
    const canvas = this.el.getElementsByTagName('canvas')[0];
    const type = this.el.dataset.chartType || '';
    const data = this.el.dataset.chartData
      ? JSON.parse(this.el.dataset.chartData)
      : {};
    const options = this.el.dataset.chartOptions
      ? JSON.parse(this.el.dataset.chartOptions)
      : { responsive: true };

    this.chart = new Chart(canvas, {
      type: type,
      data: data,
      options: options,
    });
  },
};

export { ChartHook };
