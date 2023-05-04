part of yandex_mapkit_web;

/// A widget which displays a map using Yandex maps service.
class YandexMap extends StatefulWidget {
  /// A `Widget` for displaying Yandex Map Web
  const YandexMap({
    Key? key,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
    this.mapObjects = const [],
    this.mapObjectsWeb = const [],
    this.tiltGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.modelsEnabled = true,
    this.nightModeEnabled = false,
    this.fastTapEnabled = false,
    this.mode2DEnabled = false,
    this.logoAlignment = const MapAlignment(horizontal: HorizontalAlignment.right, vertical: VerticalAlignment.bottom),
    this.focusRect,
    this.onMapCreated,
    this.onMapTap,
    this.onMapLongTap,
    this.onUserLocationAdded,
    this.onCameraPositionChanged,
    this.onTrafficChanged,
    this.mapType = MapType.vector,
    this.poiLimit,
    this.onObjectTap
  }) : super(key: key);

  static const String _viewType = 'yandex_mapkit_web/yandex_map_web';

  /// Which gestures should be consumed by the map.
  ///
  /// When this set is empty, the map will only handle pointer events for gestures that
  /// were not claimed by any other gesture recognizer.
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  /// Map objects to show on map
  final List<MapObject> mapObjects;

  /// Map objects to show on map for web
  final List<dynamic> mapObjectsWeb;

  /// Enable tilt gestures, such as parallel pan with two fingers.
  final bool tiltGesturesEnabled;

  /// Enable rotation gestures, such as rotation with two fingers.
  final bool zoomGesturesEnabled;

  /// Enable rotation gestures, such as rotation with two fingers.
  final bool rotateGesturesEnabled;

  /// Enable/disable zoom gestures, for example: - pinch - double tap (zoom in) - tap with two fingers (zoom out)
  final bool nightModeEnabled;

  /// Enable scroll gestures, such as the pan gesture.
  final bool scrollGesturesEnabled;

  /// Enable removes the 300 ms delay in emitting a tap gesture.
  /// However, a double-tap will emit a tap gesture along with a double-tap.
  final bool fastTapEnabled;

  /// Forces the map to be flat.
  ///
  /// true - All loaded tiles start showing the "flatten out" animation; all new tiles do not start 3D animation.
  /// false - All tiles start showing the "rise up" animation.
  final bool mode2DEnabled;

  /// Enables detailed 3D models on the map.
  final bool modelsEnabled;

  /// Set logo alignment on the map
  final MapAlignment logoAlignment;

  /// Allows to set map focus to a certain rectangle instead of the whole map
  /// For more info refer to https://yandex.com/dev/maps/mapkit/doc/ios-ref/full/Classes/YMKMapWindow.html#focusRect
  final ScreenRect? focusRect;

  /// Callback method for when the map is ready to be used.
  ///
  /// Pass to [YandexMapWeb.onMapCreated] to receive a [YandexMapWebController] when the
  /// map is created.
  final MapCreatedCallback? onMapCreated;

  /// Called every time a [YandexMapWeb] is tapped.
  final ArgumentCallback<Point>? onMapTap;

  /// Called every time a [YandexMapWeb] is long tapped.
  final ArgumentCallback<Point>? onMapLongTap;

  /// Called every time when the camera position on [YandexMapWeb] is changed.
  final CameraPositionCallback? onCameraPositionChanged;

  /// Callback to be called when a user location layer icon elements have been added to [YandexMapWeb].
  ///
  /// Use this method if you want to change how users current position is displayed
  /// You can return [UserLocationView] with changed [UserLocationView.pin], [UserLocationView.arrow],
  /// [UserLocationView.accuracyCircle] to change how it is shown on the map.
  ///
  /// This is called only once when the layer is made visible for the first time
  final UserLocationCallback? onUserLocationAdded;

  /// Callback to be called where a change has occured in traffic layer.
  final TrafficChangedCallback? onTrafficChanged;

  /// Selects one of predefined map style modes optimized for particular use case(transit, driving, etc).
  /// Resets json styles set with [YandexMapWebController.setMapStyle].
  final MapType mapType;

  /// Limits the number of visible basemap POIs
  final int? poiLimit;

  /// Called every time a [YandexMapWeb] geo object is tapped.
  final ObjectTapCallback? onObjectTap;

  @override
  _YandexMapState createState() => _YandexMapState();
}

class _YandexMapState extends State<YandexMap> {
  late _YandexMapOptions _yandexMapOptions;

  /// Root object which contains all [MapObject] which were added to the map by user
  MapObjectCollection _mapObjectCollection = MapObjectCollection(
    mapId: MapObjectId('root_map_object_collection'),
    mapObjects: []
  );

  /// All [MapObject] which were created natively
  ///
  /// This mainly refers to objects that can't be created by normal means
  /// Cluster placemarks, user location objects, etc.
  final List<MapObject> _nonRootMapObjects = [];

  /// All visible [MapObject]
  ///
  /// This contains all objects that were created by any means
  List<MapObject> get _allMapObjects => _mapObjectCollection.mapObjects + _nonRootMapObjects;

  final Completer<YandexMapController> _controller = Completer<YandexMapController>();

  @override
  void initState() {
    super.initState();
    _yandexMapOptions = _YandexMapOptions.fromWidget(widget);
    _mapObjectCollection = _mapObjectCollection.copyWith(mapObjects: widget.mapObjects);
  }

  @override
  void dispose() async {
    super.dispose();
    final controller = await _controller.future;

    controller.dispose();
  }

  @override
  void didUpdateWidget(YandexMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMapOptions();
    _updateMapObjects();
  }

  void _updateMapOptions() async {
    final newOptions = _YandexMapWebOptions.fromWidget(widget);
    final updates = _yandexMapWebOptions.mapUpdates(newOptions);

    if (updates.isEmpty) {
      return;
    }

    final controller = await _controller.future;

    // ignore: unawaited_futures
    controller._updateMapOptions(updates);
    _yandexMapWebOptions = newOptions;
  }

  void _updateMapObjects() async {
    final updatedMapObjectCollection = _mapObjectCollection.copyWith(mapObjects: widget.mapObjects);
    final updates = MapObjectUpdates.from({_mapObjectCollection}, {updatedMapObjectCollection});

    final controller = await _controller.future;

    // ignore: unawaited_futures
    controller._updateMapObjects(updates.toJson());
    _mapObjectCollection = updatedMapObjectCollection;
  }

  @override
  Widget build(BuildContext context) {
    if(kIsWeb) {
      var centerPoint;
      var arrayWeb = '';
      if(widget.mapObjectsWeb.isNotEmpty){
        centerPoint = [widget.mapObjectsWeb.first['latitude'], widget.mapObjectsWeb.first['longitude']];
        widget.mapObjectsWeb.removeAt(0);
        var address;
        var title;
        for (var element in widget.mapObjectsWeb) {
          address = htmlEscape.convert(element['address']);
          title = htmlEscape.convert(element['title']);
          arrayWeb = '$arrayWeb {"type": "Feature", "id": ${element['id']}, "geometry": {"type": "Point", "coordinates": [${element['latitude']}, ${element['longitude']}]}, "properties": {"balloonContent": "<strong>$title</strong>", "clusterCaption": "$address",	"hintContent": "$address"}, "options":{"iconLayout": "default#image", "iconImageHref": "icons/location_mark.svg", "iconImageSize": [32, 32], "iconImageOffset": [-5, -38]}},';
        }
      } else {
        centerPoint = [55.76, 37.64];
      }

      var random = Random();
      var randomNumber = random.nextInt(100);
      var idMapRand = 'map-$randomNumber';

      var frame = DivElement();
      var divElement = DivElement()
          ..id = idMapRand
          ..style.width = '100%'
          ..style.height = '100%';
      frame.append(divElement);

      var dataJson = ''' {
          "type": "FeatureCollection",
          "features": [   $arrayWeb   ]
      } ''';

      var styleElement = StyleElement();

      var styleYaMaps = '''
        ymaps .ymaps-2-1-79-zoom__plus,
        ymaps .ymaps-2-1-79-zoom__minus,
        ymaps .ymaps-2-1-79-controls__control .ymaps-2-1-79-float-button {
          border-radius: 50%;
          border: 1px solid #025232;
          width: 46px;
          height: 46px;
          box-shadow: none;
          background: rgba(255, 255, 255, 0.8)
        }
        ymaps .ymaps-2-1-79-zoom__plus .ymaps-2-1-79-zoom__icon {
          background: url(icons/maps_plus.svg) no-repeat center
        }
        ymaps .ymaps-2-1-79-zoom__minus .ymaps-2-1-79-zoom__icon {
          background: url(icons/maps_minus.svg) no-repeat center
        }
        ymaps .ymaps-2-1-79-zoom__plus .ymaps-2-1-79-zoom__icon,
        ymaps .ymaps-2-1-79-zoom__minus .ymaps-2-1-79-zoom__icon,
        ymaps .ymaps-2-1-79-float-button-icon_icon_geolocation {
          width: 44px;
          height: 44px;
          border-radius: 50%;
          margin: 0;
          border: 0
        }
        ymaps .ymaps-2-1-79-zoom {
          padding: 51px 0;
          width: 46px
        }
        ymaps .ymaps-2-1-79-float-button-icon_icon_geolocation {
          background: url(icons/maps_geolocation.svg) no-repeat 8px 50%
        }
        ymaps .ymaps-2-1-79-copyright {
          display:none
        }
      ''';

      var scriptElement = ScriptElement();
      var script = '''
        setTimeout(function(){ ymaps.ready(init);
        var myMap;
        function init () {
            myMap = new ymaps.Map('$idMapRand', {
                    center: $centerPoint,
                    zoom: 10,
                    controls: []
                },
                {suppressMapOpenBlock: true}
                ),
                objectManager = new ymaps.ObjectManager({
                    clusterize: true,
                    gridSize: 32,
                    /*clusterDisableClickZoom: true,*/
                    geoObjectOpenBalloonOnClick: false,
                    clusterOpenBalloonOnClick: false
                });

            myMap.controls.add('zoomControl', {
                size: 'small',
                float: 'none',
                position: {
                    top: '24px',
                    right: '24px'
                }
            });
            //myMap.controls.add('rulerControl', { scaleLine: false });
            myMap.controls.add('geolocationControl', {
                position: {
                    bottom: '24px',
                    right: '24px'
                }
            });
            
            function onObjectEvent (e) {
                var objectId = e.get('objectId');
                if (e.get('type') == 'mouseenter') {
                    // Метод setObjectOptions позволяет задавать опции объекта "на лету".
                    objectManager.objects.setObjectOptions(objectId, {
                        preset: 'islands#yellowIcon'
                    });
                } else {
                    objectManager.objects.setObjectOptions(objectId, {
                        preset: 'islands#blueIcon'
                    });
                }
            }

            function onClusterEvent (e) {
                var objectId = e.get('objectId');
                if (e.get('type') == 'mouseenter') {
                    objectManager.clusters.setClusterOptions(objectId, {
                        preset: 'islands#yellowClusterIcons'
                    });
                } else {
                    objectManager.clusters.setClusterOptions(objectId, {
                        preset: 'islands#blueClusterIcons'
                    });
                }
            }
            
            function testFunc(e){ 
                var objectId = e.get('objectId'); 
                console.log(objectId);
                modalShowInJs();
            }

            objectManager.objects.events.add(['mouseenter', 'mouseleave'], onObjectEvent);
            objectManager.clusters.events.add(['mouseenter', 'mouseleave'], onClusterEvent);
            objectManager.objects.events.add('click', testFunc);

           /* objectManager.objects.options.set('preset', 'islands#greenDotIcon');
            objectManager.clusters.options.set('preset', 'islands#greenClusterIcons');*/
            objectManager.add($dataJson);
            myMap.geoObjects.add(objectManager);

            myMap.setBounds(myMap.geoObjects.getBounds(),{checkZoomRange:true, zoomMargin:9});
        }},1000);
        ''';
      scriptElement.innerHtml = script;
      styleElement.innerHtml = styleYaMaps;
      frame.append(scriptElement);
      frame.append(styleElement);

      var registerYandexMapId = '${YandexMap._viewType}_$randomNumber';

      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
          registerYandexMapId,
              (int viewId) => frame);
      return HtmlElementView(viewType: registerYandexMapId);
    }
  }

  Future<void> _onPlatformViewCreated(int id) async {
    final controller = await YandexMapWebController._init(id, this);

    _controller.complete(controller);

    if (widget.onMapCreated != null) {
      widget.onMapCreated!(controller);
    }
  }

  Map<String, dynamic> _creationParams() {
    final mapOptions = _yandexMapWebOptions.toJson();
    final mapObjects = MapObjectUpdates.from(
      {_mapObjectCollection.copyWith(mapObjects: [])},
      {_mapObjectCollection}
    ).toJson();

    return {
      'mapOptions': mapOptions,
      'mapObjects': mapObjects
    };
  }
}

/// Configuration options for the YandexMap native view.
class _YandexMapOptions {
  _YandexMapOptions.fromWidget(YandexMap map) :
    tiltGesturesEnabled = map.tiltGesturesEnabled,
    zoomGesturesEnabled = map.zoomGesturesEnabled,
    rotateGesturesEnabled = map.rotateGesturesEnabled,
    scrollGesturesEnabled = map.scrollGesturesEnabled,
    modelsEnabled = map.modelsEnabled,
    nightModeEnabled = map.nightModeEnabled,
    fastTapEnabled = map.fastTapEnabled,
    mode2DEnabled = map.mode2DEnabled,
    logoAlignment = map.logoAlignment,
    focusRect = map.focusRect,
    mapType = map.mapType,
    poiLimit = map.poiLimit;

    final bool tiltGesturesEnabled;

    final bool zoomGesturesEnabled;

    final bool rotateGesturesEnabled;

    final bool nightModeEnabled;

    final bool scrollGesturesEnabled;

    final bool fastTapEnabled;

    final bool mode2DEnabled;

    final bool modelsEnabled;

    final MapAlignment logoAlignment;

    final ScreenRect? focusRect;

    final MapType mapType;

    final int? poiLimit;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tiltGesturesEnabled': tiltGesturesEnabled,
      'zoomGesturesEnabled': zoomGesturesEnabled,
      'rotateGesturesEnabled': rotateGesturesEnabled,
      'nightModeEnabled': nightModeEnabled,
      'scrollGesturesEnabled': scrollGesturesEnabled,
      'fastTapEnabled': fastTapEnabled,
      'mode2DEnabled': mode2DEnabled,
      'modelsEnabled': modelsEnabled,
      'logoAlignment': logoAlignment.toJson(),
      'focusRect': focusRect?.toJson(),
      'mapType': mapType.index,
      'poiLimit': poiLimit
    };
  }

  Map<String, dynamic> mapUpdates(_YandexMapOptions newOptions) {
    final prevOptionsMap = toJson();

    return newOptions.toJson()..removeWhere((String key, dynamic value) => prevOptionsMap[key] == value);
  }
}
