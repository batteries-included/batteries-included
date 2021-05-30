import Chart from 'chart.js/auto';

export default {
  getData() {
    return JSON.parse(this.el.dataset.data);
  },
  mounted() {
    const ctx = this.el.getContext('2d');
    const initData = this.getData();
    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        datasets: [
          {
            fill: false,
            data: initData,
          },
        ],

        labels: Array(initData.length)
          .fill()
          .map((_, i) => i),
      },

      // Configuration options go here
      options: {
        responsive: false,
        bezierCurve: false,
        legend: {
          display: false,
        },
        elements: {
          line: {
            borderColor: '#fc408a',
            borderWidth: 2,
          },
          point: {
            radius: 0,
          },
        },
        tooltips: {
          enabled: false,
        },
        scales: {
          yAxes: [
            {
              display: false,
            },
          ],
          xAxes: [
            {
              display: false,
            },
          ],
        },
      },
    });
  },

  updated() {
    if (this.chart && this.chart.data && this.chart.data.datasets) {
      const newData = this.getData();
      this.chart.data.datasets[0].data = newData;

      if (newData.length !== (this.chart.data.labels || []).length) {
        this.chart.data.labels = Array(newData.length)
          .fill()
          .map((_, i) => i);
      }
      this.chart.update(0);
    }
  },
};
