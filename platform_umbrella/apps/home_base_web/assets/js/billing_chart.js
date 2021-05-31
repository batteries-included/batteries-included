import Chart from 'chart.js/auto';

export default {
  getData() {
    return JSON.parse(this.el.dataset.data);
  },
  mounted() {
    const ctx = this.el.getContext('2d');
    const initData = this.getData();

    const labels = Object.keys(initData).map((l) => l.replace('.000000', ''));
    const values = Object.values(initData).map((x) => x.num_pods);
    const data = {
      labels,
      datasets: [
        {
          label: 'Reported Pods',
          data: values,
          borderColor: '#fc408b',
          backgroundColor: '#fc408b',
        },
      ],
    };

    const config = {
      type: 'line',
      data,
      options: {
        responsive: true,
        plugins: {
          legend: {
            position: 'top',
          },
        },
      },
    };

    this.chart = new Chart(ctx, config);
  },

  updated() {
    if (this.chart && this.chart.data && this.chart.data.datasets) {
      const newData = this.getData();
      this.chart.data.datasets[0].data = newData;

      this.chart.update(0);
    }
  },
};
