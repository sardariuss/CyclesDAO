import { Scatter }            from 'react-chartjs-2'

export const ScatterChart = ({ chartData, annotation }: any) => {
  return (
    <div>
      <Scatter
        data={chartData}
        options={{
          elements: {
            point:{
                radius: 0
            },
            line:{
              borderWidth: 1
            }
          },
          scales:{
            y:{
              suggestedMin: 0
            },
            x:{
              ticks:{
                callback: function(value, index, values){
                  const date = new Date(value);
                  return date.toLocaleDateString('en-US');
                }
              }
            }
          },
          plugins:{
            legend:{
              display: false
            },
            annotation: annotation,
          }
        }}
      />
    </div>
  );
};

export type ScatterData = {
  x: number,
  y: number
}