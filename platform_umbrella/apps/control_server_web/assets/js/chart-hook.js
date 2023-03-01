import Chart from 'chart.js/auto';

const colors = [
  '#fecfe2',
  '#c8dee7',
  '#fd79ae',
  '#66a3bd',
  '#e33a7d',
  '#206f90',
];

const ChartHook = {
  mounted() {
    const canvas = this.el.getElementsByTagName('canvas')[0];
    const type = this.el.dataset.chartType || '';
    const data = this.el.dataset.chartData
      ? JSON.parse(this.el.dataset.chartData)
      : {};
    const options = this.el.dataset.chartOptions
      ? JSON.parse(this.el.dataset.chartOptions)
      : { responsive: true, plugins: { legend: { position: 'bottom' } } };

    this.chart = new Chart(canvas, {
      type: type,
      data: {
        ...data,
        datasets: data.datasets.map((ds) => {
          return { backgroundColor: colors, ...ds };
        }),
      },
      options: options,
    });
  },
};

export { ChartHook };
