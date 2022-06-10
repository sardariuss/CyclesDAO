import { Bar }            from 'react-chartjs-2'
import { Chart, registerables } from 'chart.js';
Chart.register(...registerables);

const MyChart = ({ chartData }) => {
  return (
    <div>
      <Bar
        data={chartData}
        options={{
          plugins: {
            legend: {
              display: true,
              position: "bottom"
           }
          }
        }}
      />
    </div>
  );
};

export default MyChart;