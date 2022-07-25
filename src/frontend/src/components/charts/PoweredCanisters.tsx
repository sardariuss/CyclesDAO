import { CyclesProfile } from "../../../declarations/cyclesProvider/cyclesProvider.did.js";
import { useEffect, useState } from "react";
import { toTrillions } from "../../utils/conversion";

import { Bar }            from 'react-chartjs-2'
import { Chart, registerables } from 'chart.js';
import annotationPlugin, { AnnotationOptions, AnnotationPluginOptions, AnnotationTypeRegistry } from 'chartjs-plugin-annotation';
import autocolors from 'chartjs-plugin-autocolors';

Chart.register(autocolors);
Chart.register(annotationPlugin);
Chart.register(...registerables);

const addBox = (listBoxes: AnnotationOptions<keyof AnnotationTypeRegistry>[], index: number, threshold: number, target: number) => {
  // Bottom
  listBoxes.push({
    type: 'box',
    xMin: index -0.35,
    xMax: index + 0.35,
    yMin: threshold,
    yMax: threshold,
    borderColor: 'rgba(220, 220, 220, 1)',
    borderWidth: 2
  });
  // Top
  listBoxes.push({
    type: 'box',
    xMin: index - 0.35,
    xMax: index + 0.35,
    yMin: target,
    yMax: target,
    borderColor: 'rgba(220, 220, 220, 1)',
    borderWidth: 2
  });
  // Vertical bar
  listBoxes.push({
    type: 'box',
    xMin: index,
    xMax: index,
    yMin: threshold,
    yMax: target,
    borderColor: 'rgba(220, 220, 220, 1)',
    borderWidth: 2
  });
}

const BarChart = ({ chartData, annotation }: any) => {
  return (
    <div>
      <Bar
        data={chartData}
        options={{
          plugins: {
            autocolors: {
              mode: 'dataset'
            },
            annotation: annotation,
            legend:{
              display: false
            }
          }
        }}
      />
    </div>
  );
};

function PoweredCanisters({cyclesProviderActor}: any) {

  const [chartData, setChartData] = useState({})
  const [haveData, setHaveData] = useState(false);
  const [annotation, setAnnotation] = useState<AnnotationPluginOptions>({annotations: []});

  const fetch_data = async () => {
		try {
      const cyclesProfile = await cyclesProviderActor.getCyclesProfile() as Array<CyclesProfile>;

      setChartData({
        labels: cyclesProfile.map((profile) => profile.principal),
        datasets: [{
            label: "Cycles balance",
            data: cyclesProfile.map((profile) => {return toTrillions(profile.balance_cycles)}),
            backgroundColor:'#8c4232'
        }],
      });

      let listBoxes: AnnotationOptions<keyof AnnotationTypeRegistry>[] = [];
      cyclesProfile.map((profile, index) => {addBox(listBoxes, index, toTrillions(profile.powering_parameters.balance_threshold), toTrillions(profile.powering_parameters.balance_target))});
      setAnnotation({ annotations : listBoxes });
      setHaveData(true);

    } catch (err) {
      console.error(err);
      setHaveData(false);
		}
  }

  useEffect(() => {
    fetch_data();
	}, []);

  if (!haveData) {
    return (
      <></>
    );
  } else {
    return (
      <>
        <BarChart chartData={chartData} annotation={annotation} />
      </>
    )
  };
}

export default PoweredCanisters;