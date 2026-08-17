import 'package:maplibre_gl/maplibre_gl.dart';

const pointsSourceId = 'refuges-info-points';
const clusterLayerId = 'refuges-info-clusters-layer';
const clusterCountLayerId = 'refuges-info-cluster-count-layer';
const pointLayerId = 'refuges-info-points-layer';

const clusterFilter = <Object>['has', 'point_count'];
const individualPointFilter = <Object>[
  '!',
  <Object>['has', 'point_count'],
];

const clusterCircleStyle = CircleLayerProperties(
  circleRadius: <Object>[
    'step',
    <Object>['get', 'point_count'],
    18,
    25,
    22,
    100,
    27,
  ],
  circleColor: <Object>[
    'step',
    <Object>['get', 'point_count'],
    '#4F806C',
    25,
    '#315C4C',
    100,
    '#1E4034',
  ],
  circleStrokeColor: '#FFFFFF',
  circleStrokeWidth: 2,
);

const clusterCountStyle = SymbolLayerProperties(
  textField: <Object>['get', 'point_count_abbreviated'],
  textFont: <String>['Noto Sans Bold'],
  textSize: 12,
  textColor: '#FFFFFF',
  textAllowOverlap: true,
  textIgnorePlacement: true,
);

const individualPointStyle = CircleLayerProperties(
  circleRadius: 7,
  circleColor: '#315C4C',
  circleStrokeColor: '#FFFFFF',
  circleStrokeWidth: 2,
);

GeojsonSourceProperties pointsSource(Map<String, dynamic> data) {
  return GeojsonSourceProperties(
    data: data,
    attribution: 'Données Refuges.info - CC BY-SA 2.0',
  );
}
