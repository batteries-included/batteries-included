import Chart from 'chart.js/auto';
import { ViewHook } from 'phoenix_live_view';

export interface ChartHookInterface extends ViewHook {
  chart: Chart;
}

export const ChartHook = {
  mounted() {
    const canvas = this.el.getElementsByTagName('canvas')[0];

    this.options = JSON.parse(this.el.dataset.options || '{}');
    this.data = JSON.parse(this.el.dataset.encoded || '{}');

    this.chart = new Chart(canvas, {
      type: this.el.dataset.type,
      options: this.options,
      data: this.data,
      plugins: [this.overlappingRoundedSegments()],
    });
  },
  updated() {
    const data = JSON.parse(this.el.dataset.encoded || '{}');

    this.chart.data = data;
    this.chart.update('none');
  },
  overlappingRoundedSegments() {
    return {
      id: 'overlappingRoundedSegments',
      afterDatasetsDraw: (chart, args, plugins) => {
        const { data } = chart.getDatasetMeta(0);

        data.forEach((value, index) => {
          if (chart.getDataVisibility(index)) {
            const { innerRadius, outerRadius, endAngle } = data[index];
            const radius = (outerRadius - innerRadius) / 2;

            const xCoor = (innerRadius + radius) * Math.cos(endAngle + Math.PI);
            const yCoor = (innerRadius + radius) * Math.sin(endAngle);

            chart.ctx.save();

            chart.ctx.translate(data[0].x, data[0].y);
            chart.ctx.beginPath();
            chart.ctx.arc(-xCoor, yCoor, radius, 0, Math.PI * 2, false);

            chart.ctx.fillStyle =
              this.options.backgroundColor[
                index >= this.options.backgroundColor.length
                  ? index - this.options.backgroundColor.length
                  : index
              ];

            chart.ctx.fill();
            chart.ctx.restore();
          }
        });
      },
    };
  },
} as ChartHookInterface;
