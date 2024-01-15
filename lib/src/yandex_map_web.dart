part of yandex_mapkit_web;

/// A widget which displays a map using Yandex maps service.
class YandexMapWeb extends StatefulWidget {
  /// A `Widget` for displaying Yandex Map Web
  const YandexMapWeb({
    Key? key,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
    this.mapObjects = const [],
    this.mapObjectsWeb = const [],
    this.showControls = true,
    this.typeMap = 'default',
    this.typeBalloon = 'default',
    this.minZoom = 1,
    this.clusterDisableClickZoom = false,
    this.geolocationControlPositionTop = false,
    this.pointDisableClickZoom = false,
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

  final bool showControls;

  final String typeMap;

  final String typeBalloon;

  final bool clusterDisableClickZoom;

  final bool geolocationControlPositionTop;

  final bool pointDisableClickZoom;

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

  final int minZoom;

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

class _YandexMapState extends State<YandexMapWeb> {
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
  void didUpdateWidget(YandexMapWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMapOptions();
    _updateMapObjects();
  }

  void _updateMapOptions() async {
    final newOptions = _YandexMapOptions.fromWidget(widget);
    final updates = _yandexMapOptions.mapUpdates(newOptions);

    if (updates.isEmpty) {
      return;
    }

    final controller = await _controller.future;

    // ignore: unawaited_futures
    controller._updateMapOptions(updates);
    _yandexMapOptions = newOptions;
  }

  void _updateMapObjects() async {
    final updatedMapObjectCollection = _mapObjectCollection.copyWith(mapObjects: widget.mapObjects);
    final updates = MapObjectUpdates.from({_mapObjectCollection}, {updatedMapObjectCollection});

    final controller = await _controller.future;

    // ignore: unawaited_futures
    controller._updateMapObjects(updates.toJson());
    _mapObjectCollection = updatedMapObjectCollection;
  }

  // kReleaseMode path assets
  String assetsPath = kReleaseMode ? 'assets/packages/yandex_mapkit_web/assets' : 'packages/yandex_mapkit_web/assets';

  // address sprite
  late final String addressSprite = '$assetsPath/address_sprite.png';
  // clusters
  late final String clustersSvg = '$assetsPath/clusters.svg';
  // Control images
  late final String mapsGeolocationSvg = '$assetsPath/maps_geolocation.svg';
  late final String mapsMinusSvg = '$assetsPath/maps_minus.svg';
  late final String mapsPlusSvg = '$assetsPath/maps_plus.svg';

  @override
  Widget build(BuildContext context) {

    var typeMapWidget;

    final minZoomMap = widget.minZoom;
    var clusterDisableClickZoomParam = widget.clusterDisableClickZoom ? 'true' : 'false';

    var geolocationControlPositionTop = widget.geolocationControlPositionTop ? 'top: "146px"' : 'bottom: "24px"';

    var nightMode = widget.nightModeEnabled ? '''
      var nightModeLayer = function () {
        return new ymaps.Layer('https://core-renderer-tiles.maps.yandex.net/tiles?l=map&theme=dark&%c&%l&scale={{ scale }}');
      }
      ymaps.layer.storage.add('avangard#nightMode', nightModeLayer);
      var nightModeType = new ymaps.MapType('Night Mode Layer', ['avangard#nightMode']);
      ymaps.mapType.storage.add('avangard#mapNightModeType', nightModeType);
      myMap.setType('avangard#mapNightModeType');
    ''' : '';

    var pointClickZoom = widget.pointDisableClickZoom ? '' : '''
          myMap.panTo(coordPosition, {flying: true }).then(
                          function(){
                              if(myMap.getZoom() < 15){
                                  myMap.setZoom(15, {smooth: true, duration: 1000});
                              }
                              myMap.setZoom(15, {smooth: true, duration: 1000});
                          }
                      );
      ''';

    switch(widget.typeMap) {
      case 'default':
        typeMapWidget = '';
        break;
      case 'details':
        typeMapWidget = '''
            function changeMarker(marker) {            
                objectManager.objects.each(function (object) {
                    var objectPreset = objectManager.objects.getById(object.id).options.preset;
                    if (objectPreset.indexOf('#active') != -1 && object.id != marker) {
                        var objectPresetDefault = objectPreset.replace('#active', '#default');     
                        objectManager.objects.setObjectOptions(object.id, {
                          preset: objectPresetDefault
                        });
                    } 
                });
                
                var presetInput = objectManager.objects.getById(marker).options.preset;
                
                var objectPresetName;
                if (presetInput.indexOf('#active') != -1) {
                    objectPresetName = presetInput.replace('#active', '#default');
                } else {
                    objectPresetName = presetInput.replace('#default', '#active');
                }               
                objectManager.objects.setObjectOptions(marker, {
                  preset: objectPresetName
                });
            }
                
            function pointFunc(e){
                var objectId = e.get('objectId');
                var coordPosition = objectManager.objects.getById(objectId).geometry.coordinates;
                changeMarker(objectId);
                onPlaceMarkClick(objectId);
                $pointClickZoom
            }
            function clusterFunc(e){    
                var cluster = objectManager.clusters.getById(e.get('objectId')),
                    objects = cluster.properties.geoObjects;
                let clusterArray = [];
                objects.forEach(function(item, i, arr) {
                  clusterArray.push(item.id);
                });
                onClustersClick(JSON.stringify(clusterArray));
            }
                    
            window.changeMarkerFunc = function(marker){ changeMarker(marker); };
            window.goToMark = function(latitude, longitude, marker){
                if(typeof(marker) != "undefined"){
                    changeMarker(marker);
                }
                if(myMap.getZoom() < 15){
                    myMap.setZoom(15, {smooth: true, duration: 1000}).then(
                        function(){
                            myMap.panTo([latitude, longitude], {flying: true });
                        }
                    );
                } else {
                    myMap.panTo([latitude, longitude], {flying: true });
                }
            }                    
            
            objectManager.objects.events.add('click', pointFunc);
            objectManager.clusters.events.add('click', clusterFunc);
          ''';
        break;
      case 'discounts':
        typeMapWidget = '''                  
            function changeMarker(marker) {                      
              objectManager.objects.each(function (object) {
                  var objectPreset = objectManager.objects.getById(object.id).options.preset;
                  if (objectPreset.indexOf('#active') != -1 && object.id != marker) {
                      var objectPresetDefault = objectPreset.replace('#active', '#default');     
                      objectManager.objects.setObjectOptions(object.id, {
                        preset: objectPresetDefault
                      });
                  } 
              });
                        
              var presetInput = objectManager.objects.getById(marker).options.preset;
              
              var objectPresetName;
              if (presetInput.indexOf('#active') != -1) {
                  objectPresetName = presetInput.replace('#active', '#default');
              } else {
                  objectPresetName = presetInput.replace('#default', '#active');
              }               
              objectManager.objects.setObjectOptions(marker, {
                preset: objectPresetName
              });
            }                  
                  
            function selectedPoint(e){
                var objectId = e.get('objectId');
                var coordPosition = objectManager.objects.getById(objectId).geometry.coordinates;
                onPlaceMarkClick(objectId);
                myMap.panTo(coordPosition, {flying: true }).then(
                    function(){
                        if(myMap.getZoom() < 15){
                            myMap.setZoom(15, {smooth: true, duration: 1000});
                        }
                        myMap.setZoom(15, {smooth: true, duration: 1000});
                    }
                );
            }
            window.goToMark = function(latitude, longitude){
                myMap.panTo([latitude, longitude], {flying: true }).then(
                    function(){
                        if(myMap.getZoom() < 15){
                            myMap.setZoom(15, {smooth: true, duration: 1000});
                        }
                    }
                );
            }
            objectManager.objects.events.add('click', selectedPoint);
          ''';
        break;
    }

    var typeBalloonWidget = 'office';
    switch(widget.typeBalloon) {
      case 'default':
        typeBalloonWidget = 'office';
        break;
      case 'percent':
        typeBalloonWidget = 'percent';
        break;
    }


    var centerPoint;
    var arrayWeb = '';
    var setBounds;
    var getLocation = '';

    if(widget.mapObjectsWeb.isNotEmpty){
      centerPoint = [widget.mapObjectsWeb.first['latitude'], widget.mapObjectsWeb.first['longitude']];

      setBounds = widget.mapObjectsWeb.length > 1 ? 'myMap.setBounds(myMap.geoObjects.getBounds(),{checkZoomRange:true, zoomMargin:9});' : '';

      var address;
      var title;
      for (var element in widget.mapObjectsWeb) {
        if(element['pointType'] != null && element['pointType']?.isNotEmpty) {
          typeBalloonWidget = element['pointType'];
        }
        address = htmlEscape.convert(element['address']);
        title = htmlEscape.convert(element['title']);
        arrayWeb = '$arrayWeb {"type": "Feature", "id": ${element['id']}, "geometry": {"type": "Point", "coordinates": [${element['latitude']}, ${element['longitude']}]}, "properties": {"balloonContent": "<strong>$title</strong>", "clusterCaption": "$address", "preset": "office#active",	"hintContent": "$address"}, "options":{"preset": "$typeBalloonWidget#default"}},';
      }

      if(widget.typeMap == 'discounts'){
        getLocation = widget.mapObjectsWeb.length > 1 ? '''
           myMap.panTo($centerPoint, {flying: true }).then(
                    function(){
                        if(myMap.getZoom() < 15){
                            myMap.setZoom(15, {smooth: true, duration: 1000});
                        }
                    }
                );
        ''' : setBounds;
      } else {
        getLocation = ''' location.get({
            mapStateAutoApply: true,
            provider: 'browser'
          }).then(
            function(result) {
              if(localStorage.getItem('location_access_browser') == null || localStorage.getItem('location_access_browser') != 1) {
                myMap.geoObjects.add(result.geoObjects);
                localStorage.setItem('location_access_browser', 1);
              }
            }
          );
          
          $setBounds
          
        ''';
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
        @keyframes ldio-mce4sjvnvsr {
          0% { transform: translate(-50%,-50%) rotate(0deg); }
          100% { transform: translate(-50%,-50%) rotate(360deg); }
        }
        div[id^=map].preloader {
          position: relative
        }
        div[id^=map].preloader:before {
          content: '';
          display: block;
          position: absolute;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          background: #ffffff70;
          opacity: 1;
          z-index: 1;
          transition: opacity 1s ease;
        }
        div[id^=map].preloader:after {
          content: '';
          display: block;
          position: absolute;
          opacity: 1;
          z-index: 1;
          top: 50%;
          left: 50%;
          width: 92px;
          height: 92px;
          border: 4px solid #025232;
          border-top-color: transparent;
          border-radius: 50%;
          animation: ldio-mce4sjvnvsr 1s linear infinite;
          box-sizing: content-box
          transition: opacity 1s ease;
        }
        div[id^=map]:before,
        div[id^=map]:after {
          opacity: 0
        }
        div[id^=map].nb:before,
        div[id^=map].nb:after {
          display: none;
          z-index: -1
        }
      
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
          background: url($mapsPlusSvg) no-repeat center
        }
        ymaps .ymaps-2-1-79-zoom__minus .ymaps-2-1-79-zoom__icon {
          background: url($mapsMinusSvg) no-repeat center
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
          background: url($mapsGeolocationSvg) no-repeat 8px 50%
        }
        ymaps .ymaps-2-1-79-copyright,
        ymaps .ymaps-2-1-79-default-cluster ymaps {
          display:none
        }
      ''';

    var scriptElement = ScriptElement();
    var controls;

    if(widget.showControls){
      controls = '''
              myMap.controls.add('zoomControl', {
                  size: 'small',
                  float: 'none',
                  position: {
                      top: '24px',
                      right: '24px'
                  }
              });
              myMap.controls.add('geolocationControl', {
                position: {
                    $geolocationControlPositionTop,
                    right: '24px'
                }
            });
          ''';
    } else {
      controls = '';
    }

    var presets = '''
            ymaps.option.presetStorage.add('office#default', {
              iconLayout: 'default#image',
              iconImageHref: '$addressSprite',
              iconImageSize: [24, 34],
              iconImageOffset: [-5, -38],
              iconImageClipRect: [
                [208, 3],
                [232, 37]
              ],
              hideIconOnBalloonOpen: false
            });
            ymaps.option.presetStorage.add('office#active', {
              iconLayout: 'default#image',
              iconImageHref: '$addressSprite',
              iconImageSize: [24, 34],
              iconImageOffset: [-5, -40],
              iconImageClipRect: [
                [208, 43],
                [232, 77]
              ],
              hideIconOnBalloonOpen: false
            });
                
            ymaps.option.presetStorage.add('percent#default', {
              iconLayout: 'default#image',
              iconImageHref: '$addressSprite',
              iconImageSize: [24, 34],
              iconImageOffset: [-5, -38],
              iconImageClipRect: [
                [128, 3],
                [152, 37]
              ],
              hideIconOnBalloonOpen: false
            });  
            ymaps.option.presetStorage.add('percent#active', {
              iconLayout: 'default#image',
              iconImageHref: '$addressSprite',
              iconImageSize: [24, 34],
              iconImageOffset: [-5, -38],
              iconImageClipRect: [
                [128, 43],
                [152, 77]
              ],
              hideIconOnBalloonOpen: false
            });
            
            ymaps.option.presetStorage.add('atmFull#default', {
              iconLayout: 'default#image',
              iconImageHref: '$addressSprite',
              iconImageSize: [24, 34],
              iconImageOffset: [-5, -38],
              iconImageClipRect: [
                [8, 3],
                [32, 37]
              ],
              hideIconOnBalloonOpen: false
            });  
            ymaps.option.presetStorage.add('atmFull#active', {
              iconLayout: 'default#image',
              iconImageHref: '$addressSprite',
              iconImageSize: [24, 34],
              iconImageOffset: [-5, -38],
              iconImageClipRect: [
                [8, 43],
                [32, 77]
              ],
              hideIconOnBalloonOpen: false
            });
            
            ymaps.option.presetStorage.add('atmWithdrawal#default', {
              iconLayout: 'default#image',
              iconImageHref: '$addressSprite',
              iconImageSize: [24, 34],
              iconImageOffset: [-5, -38],
              iconImageClipRect: [
                [88, 3],
                [112, 37]
              ],
              hideIconOnBalloonOpen: false
            });  
            ymaps.option.presetStorage.add('atmWithdrawal#active', {
              iconLayout: 'default#image',
              iconImageHref: '$addressSprite',
              iconImageSize: [24, 34],
              iconImageOffset: [-5, -38],
              iconImageClipRect: [
                [88, 43],
                [112, 77]
              ],
              hideIconOnBalloonOpen: false
            });
            
            ymaps.option.presetStorage.add('atmAcceptance#default', {
              iconLayout: 'default#image',
              iconImageHref: '$addressSprite',
              iconImageSize: [24, 34],
              iconImageOffset: [-5, -38],
              iconImageClipRect: [
                [48, 3],
                [72, 37]
              ],
              hideIconOnBalloonOpen: false
            });  
            ymaps.option.presetStorage.add('atmAcceptance#active', {
              iconLayout: 'default#image',
              iconImageHref: '$addressSprite',
              iconImageSize: [24, 34],
              iconImageOffset: [-5, -38],
              iconImageClipRect: [
                [48, 43],
                [72, 77]
              ],
              hideIconOnBalloonOpen: false
            });
      ''';

    var script = '''
            
        document.querySelector('[id^=map]').classList.add('preloader');
                  
        setTimeout(function(){ ymaps.ready(init);
        var myMap;
        function init () {

            $presets
        
            var location = ymaps.geolocation;
            myMap = new ymaps.Map('$idMapRand', {
                    center: $centerPoint,
                    zoom: 15,
                    controls: []
                },
                {
                    minZoom: $minZoomMap,
                    maxZoom: 17,
                    suppressMapOpenBlock: true,
                    yandexMapDisablePoiInteractivity: true,
                    restrictMapArea: [
                        [85,-30],
                        [-85,329.99]
                    ]
                }
                ),
                objectManager = new ymaps.ObjectManager({
                    clusterize: true,
                    gridSize: 60,
                    clusterDisableClickZoom: $clusterDisableClickZoomParam,
                    geoObjectOpenBalloonOnClick: false,
                    clusterOpenBalloonOnClick: false
                });
                
                objectManager.clusters.options.set({
                    clusterIcons: [{
                        href: '$clustersSvg',
                        size: [24, 34],
                        offset: [-20, -20]
                    }]
                });

            $controls            
            
            $typeMapWidget         

            objectManager.add($dataJson);
            myMap.geoObjects.add(objectManager);
            
            let orientationListener = function(mapListener) {
               function resizeMapContainer(mapListener){ mapListener.container.fitToViewport(); }
               setTimeout(function(){ resizeMapContainer(mapListener); },100);
            };
            window.addEventListener('orientationchange', () => orientationListener(myMap));
                        
            $getLocation
            
            $nightMode
            
            var layer = myMap.layers.get(0).get(0);
          
            waitForTilesLoad(layer).then(function() {
              document.querySelector('[id^=map]').classList.remove('preloader');
              setTimeout(function(){ document.querySelector('[id^=map]').classList.add('nb') },1000);
            });            
        }
        },1000);
        
        function waitForTilesLoad(layer) {
          return new ymaps.vow.Promise(function (resolve, reject) {
            var tc = getTileContainer(layer), readyAll = true;
            tc.tiles.each(function (tile, number) {
              if (!tile.isReady()) {
                readyAll = false;
              }
            });
            if (readyAll) {
              resolve();
            } else {
              tc.events.once("ready", function() {
                resolve();
              });
            }
          });
        }
        
        function getTileContainer(layer) {
          for (var k in layer) {
            if (layer.hasOwnProperty(k)) {
              if (
                layer[k] instanceof ymaps.layer.tileContainer.CanvasContainer
                || layer[k] instanceof ymaps.layer.tileContainer.DomContainer
              ) {
                return layer[k];
              }
            }
          }
          return null;
        }
                
        ''';
    scriptElement.innerHtml = script;
    styleElement.innerHtml = styleYaMaps;
    frame.append(scriptElement);
    frame.append(styleElement);

    var registerYandexMapId = '${YandexMapWeb._viewType}_$randomNumber';

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
        registerYandexMapId,
            (int viewId) => frame);
    return HtmlElementView(viewType: registerYandexMapId);
  }

  Future<void> _onPlatformViewCreated(int id) async {
    final controller = await YandexMapController._init(id, this);

    _controller.complete(controller);

    if (widget.onMapCreated != null) {
      widget.onMapCreated!(controller);
    }
  }

  Map<String, dynamic> _creationParams() {
    final mapOptions = _yandexMapOptions.toJson();
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
  _YandexMapOptions.fromWidget(YandexMapWeb map) :
        showControls = map.showControls,
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

  final bool showControls;

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
      'showControls': showControls,
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
