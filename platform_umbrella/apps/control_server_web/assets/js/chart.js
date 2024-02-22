import Chart from 'chart.js/auto';

const colors = [
  '#fecfe2',
  '#c8dee7',
  '#fd79ae',
  '#66a3bd',
  '#e33a7d',
  '#206f90',
];

export const ChartHook = {
  updated() {
    const data = this.el.dataset.chartData
      ? JSON.parse(this.el.dataset.chartData)
      : {};

    const enrichedData = {
      ...data,
      datasets: this.enrichDatasets(data.datasets),
    };
    this.chart.data = enrichedData;
    this.chart.update('none');

    console.log(enrichedData);
  },

  enrichDatasets(datasets) {
    return datasets.map((ds) => {
      return { backgroundColor: colors, ...ds };
    });
  },

  mounted() {
    const canvas = this.el.getElementsByTagName('canvas')[0];
    const type = this.el.dataset.chartType || '';
    const data = this.el.dataset.chartData
      ? JSON.parse(this.el.dataset.chartData)
      : {};
    const options = this.el.dataset.chartOptions
      ? JSON.parse(this.el.dataset.chartOptions)
      : {
          responsive: true,
          plugins: {
            legend: { position: 'bottom', labels: { font: { size: 16 } } },
          },
        };

    this.chart = new Chart(canvas, {
      type: type,
      data: {
        ...data,
        datasets: this.enrichDatasets(data.datasets),
      },
      options: options,
    });
  },
};
