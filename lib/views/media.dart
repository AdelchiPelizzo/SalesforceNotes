import 'dart:async';
import 'dart:io';
import 'package:exif/exif.dart';
import 'package:latlong_to_osgrid/latlong_to_osgrid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:salesforcenotes/views/create_new_note.dart';
import 'package:video_player/video_player.dart';

class AddMedia extends StatelessWidget {
  const AddMedia({super.key});

  @override
  Widget build(BuildContext context) {
    return const MediaPage(
      title: 'Image Picker Demo',
      // home: MediaPage(title: 'Image Picker Example'),
    );
  }
}

class MediaPage extends StatefulWidget {
  const MediaPage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  MediaPageState createState() => MediaPageState();
}

class MediaPageState extends State<MediaPage> {

  List<double> coordinates = [];
  LatLongConverter converter = LatLongConverter();

  Future<List<double>> printExifOf(String path) async {

    final fileBytes = File(path).readAsBytesSync();
    final data = await readExifFromBytes(fileBytes);

    if (data.isEmpty) {
      print("No EXIF information found");
    }
              //   for (final entry in data.entries) {
              //   print("${entry.key}: ${entry.value}");
              // }

              // if (data.containsKey('JPEGThumbnail')) {
              //   print('File has JPEG thumbnail');
              //   data.remove('JPEGThumbnail');
              // }
              // if(data.containsKey('GPS')){
      // for (final entry in data.entries) {
              // print("${entry.key}: ${entry.value}");
      // }
              // }
              // if (data.containsKey('TIFFThumbnail')) {
              //   print('File has TIFF thumbnail');
              //   data.remove('TIFFThumbnail');
              // }
    // void DmsToDecimalExample(var latDeg, var latMin, var latSec, var longDeg, var longMin, var longSec) {
    //     double latDec = converter.getDecimalFromDegree(latDeg, latMin, latSec);
    //     double longDec = converter.getDecimalFromDegree(longDeg, longMin, longSec);
    //     // print("$latDec $longDec");
    // }
    String latOrientation = '';
    for (final entry in data.entries) {
      if(entry.key =='GPS GPSLatitudeRef'){
        latOrientation = entry.value.toString();
        // print('latOrientation 1 '+latOrientation+' <<< 1');
      }
    }

    String lonOrientation = '';
    for (final entry in data.entries) {
      if(entry.key =='GPS GPSLongitudeRef'){
        lonOrientation = entry.value.toString();
        // print('lonOrientation 1 '+lonOrientation+ ' <<< 1');
      }
    }
    for (final entry in data.entries) {
      // if(entry.key =='GPS GPSLatitudeRef'){
      //   latOrientation = entry.value.toString();
      //   print('latOrientation 1 '+latOrientation+' <<< 1');
      // }
      // if(data.containsKey('GPS')){
        // print("${entry.key}: ${entry.value}");
      // }

      if(entry.key =='GPS GPSLatitude'){
        // print('latOrientation 2 '+latOrientation+' <<< 2' );
        // print('Latititude in DEG '+ entry.value);
        var latDEG = entry.value.values.toList();
        // for(String s in latDEG){
        //   print(" lat >>> "+s);
        // }
        var latGrades = double.parse(latDEG[0].toString());
        var latMinutes = double.parse(latDEG[1].toString());
        var latSecondsList = latDEG[2].toString().split('/');
        var latSecondsDouble = int.parse(latSecondsList[0])/int.parse(latSecondsList[1]);
        double latDecAbs = converter.getDecimalFromDegree(latGrades, latMinutes, latSecondsDouble);
        double latDec;
        if(latOrientation == "N"){
          // print('latDecAbs '+latDecAbs.toString());
          latDec = latDecAbs*1.00;
          coordinates.add(latDec);
        }else if( latOrientation == "S" ){
          latDec = latDecAbs*-1.00;
          coordinates.add(latDec);
        }
        // print(s);
        // var sl = s.split('/');
        // print(sl[0]);
        // var GPSLatValuesString = entry.value.values.toList()[2].toString();
        // var GPSLatValuesList = GPSLatValuesString.split('/');
        // var longitude = int.parse(GPSLatValuesList[0])/int.parse(GPSLatValuesList[1]);
        
      }

      if(entry.key == 'GPS GPSLongitude'){
        
        // print('lonOrientation 2 '+lonOrientation+' <<< 2' );
        // print('Longitude in DEG '+entry.value.toString());
        var lonDEG = entry.value.values.toList();
        var lonGrades = double.parse(lonDEG[0].toString());
        var lonMinutes = double.parse(lonDEG[1].toString());
        var lonSecondsList = lonDEG[2].toString().split('/');
        var lonSecondsDouble = int.parse(lonSecondsList[0])/int.parse(lonSecondsList[1]);
        double lonDecAbs = converter.getDecimalFromDegree(lonGrades, lonMinutes, lonSecondsDouble);
        double lonDec;
        
        if(lonOrientation == "E"){
          lonDec = lonDecAbs*1.00;
          coordinates.add(lonDec);
        }else if( lonOrientation == "W" ){
          print('lonDecAbs '+lonDecAbs.toString());
          lonDec = lonDecAbs*-1.00;
          coordinates.add(lonDec);
        }


        // print("${entry.key}: ${entry.value}");
        // var GPSLonValuesString = entry.value.values.toList()[2].toString();
        // var GPSLonValuesList = GPSLonValuesString.split('/');
        // var longitude = int.parse(GPSLonValuesList[0])/int.parse(GPSLonValuesList[1]);
      }
    }
    print('coordinates '+coordinates.toString());
    return coordinates;
  }

  List<XFile>? _imageFileList;

  set _imageFile(XFile? value) {
    _imageFileList = value == null ? null : [value];
  }

  dynamic _pickImageError;
  bool isVideo = false;

  VideoPlayerController? _controller;
  VideoPlayerController? _toBeDisposed;
  String? _retrieveDataError;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController maxWidthController = TextEditingController();
  final TextEditingController maxHeightController = TextEditingController();
  final TextEditingController qualityController = TextEditingController();

  Future<void> _playVideo(XFile? file) async {
    if (file != null && mounted) {
      await _disposeVideoController();
      late VideoPlayerController controller;
      if (kIsWeb) {
        controller = VideoPlayerController.network(file.path);
      } else {
        controller = VideoPlayerController.file(File(file.path));
      }
      _controller = controller;
      // In web, most browsers won't honor a programmatic call to .play
      // if the video has a sound track (and is not muted).
      // Mute the video so it auto-plays in web!
      // This is not needed if the call to .play is the result of user
      // interaction (clicking on a "play" button, for example).
      const double volume = kIsWeb ? 0.0 : 1.0;
      await controller.setVolume(volume);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      setState(() {});
    }
  }

  void _onImageButtonPressed(
    ImageSource source,
    {BuildContext? context, bool isMultiImage = false}
    ) async {
    if (_controller != null) {
      await _controller!.setVolume(0.0);
    }
    if (isVideo) {
      final XFile? file = (await _picker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: 10)));
      await _playVideo(file);
    } else if (isMultiImage) {
      await _displayPickImageDialog(context!,
          (double? maxWidth, double? maxHeight, int? quality) async {
        try {
          final pickedFileList = await _picker.pickMultiImage(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            imageQuality: quality,
          );
          setState(() {
            _imageFileList = pickedFileList.cast<XFile>();
          });
        } catch (e) {
          setState(() {
            _pickImageError = e;
          });
        }
      });
    } else {
      await _displayPickImageDialog(context!,
          (double? maxWidth, double? maxHeight, int? quality) async {
        try {
          final pickedFile = await _picker.pickImage(
            source: source,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            imageQuality: quality,
          );
          setState(() {
            _imageFile = pickedFile;
            if (pickedFile != null) {
              printExifOf(pickedFile.path);
              // Uint8List unitData =  pickedFile.openRead() as Uint8List;
              // Future<dynamic> fStream = StreamConsumer.addStream(stream);
               Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewNote(path: pickedFile.path.toString(), coord: coordinates),
                ),
              );
            }
          });
        } catch (e) {
          setState(() {
            _pickImageError = e;
          });
        }
      });
    }
  }

  @override
  void deactivate() {
    if (_controller != null) {
      _controller!.setVolume(0.0);
      _controller!.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _disposeVideoController();
    maxWidthController.dispose();
    maxHeightController.dispose();
    qualityController.dispose();
    super.dispose();
  }

  Future<void> _disposeVideoController() async {
    if (_toBeDisposed != null) {
      await _toBeDisposed!.dispose();
    }
    _toBeDisposed = _controller;
    _controller = null;
  }

  Widget _previewVideo() {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_controller == null) {
      return const Text(
        'You have not yet picked a video',
        textAlign: TextAlign.center,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: AspectRatioVideo(_controller),
    );
  }

  Widget _previewImages() {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_imageFileList != null) {
      return Semantics(
          label: 'image_picker_example_picked_images',
          child: ListView.builder(
            key: UniqueKey(),
            itemBuilder: (context, index) {
              // Why network for web?
              // See https://pub.dev/packages/image_picker#getting-ready-for-the-web-platform
              return Semantics(
                label: 'image_picker_example_picked_image',
                child: kIsWeb
                    ? Image.network(_imageFileList![index].path)
                    : Image.file(File(_imageFileList![index].path)),
              );
            },
            itemCount: _imageFileList!.length,
          ));
    } else if (_pickImageError != null) {
      return Text(
        'Pick image error: $_pickImageError',
        textAlign: TextAlign.center,
      );
    } else {
      return const Text(
        'You have not yet picked an image.',
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _handlePreview() {
    if (isVideo) {
      return _previewVideo();
    } else {
      return _previewImages();
    }
  }

  Future<void> retrieveLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      if (response.type == RetrieveType.video) {
        isVideo = true;
        await _playVideo(response.file);
      } else {
        isVideo = false;
        setState(() {
          _imageFile = response.file;
        });
      }
    } else {
      _retrieveDataError = response.exception!.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Center(
        child: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? FutureBuilder<void>(
                future: retrieveLostData(),
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return const Text(
                        'You have not yet picked an image.',
                        textAlign: TextAlign.center,
                      );
                    case ConnectionState.done:
                      return _handlePreview();
                    default:
                      if (snapshot.hasError) {
                        return Text(
                          'Pick image/video error: ${snapshot.error}}',
                          textAlign: TextAlign.center,
                        );
                      } else {
                        return const Text(
                          'You have not yet picked an image.',
                          textAlign: TextAlign.center,
                        );
                      }
                  }
                },
              )
            : _handlePreview(),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Semantics(
            label: 'image_picker_example_from_gallery',
            child: FloatingActionButton(
              onPressed: () {
                isVideo = false;
                _onImageButtonPressed(
                  ImageSource.gallery,
                  context: context,
                );
              },
              heroTag: 'image0',
              tooltip: 'Pick Image from gallery',
              child: const Icon(Icons.photo),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              onPressed: () {
                isVideo = false;
                _onImageButtonPressed(
                  ImageSource.gallery,
                  context: context,
                  isMultiImage: true,
                );
              },
              heroTag: 'image1',
              tooltip: 'Pick Multiple Image from gallery',
              child: const Icon(Icons.photo_library),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              onPressed: () {
                isVideo = false;
                _onImageButtonPressed(ImageSource.camera, context: context);
              },
              heroTag: 'image2',
              tooltip: 'Take a Photo',
              child: const Icon(Icons.camera_alt),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: () {
                isVideo = true;
                _onImageButtonPressed(ImageSource.gallery);
              },
              heroTag: 'video0',
              tooltip: 'Pick Video from gallery',
              child: const Icon(Icons.video_library),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: () {
                isVideo = true;
                _onImageButtonPressed(ImageSource.camera);
              },
              heroTag: 'video1',
              tooltip: 'Take a Video',
              child: const Icon(Icons.videocam),
            ),
          ),
        ],
      ),
    );
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Future<void> _displayPickImageDialog(
      BuildContext context, OnPickImageCallback onPick) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Add optional parameters'),
            content: Column(
              children: <Widget>[
                TextField(
                  controller: maxWidthController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(hintText: "Enter maxWidth if desired"),
                ),
                TextField(
                  controller: maxHeightController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(hintText: "Enter maxHeight if desired"),
                ),
                TextField(
                  controller: qualityController,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(hintText: "Enter quality if desired"),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                  child: const Text('PICK'),
                  onPressed: () {
                    double? width = maxWidthController.text.isNotEmpty
                        ? double.parse(maxWidthController.text)
                        : null;
                    double? height = maxHeightController.text.isNotEmpty
                        ? double.parse(maxHeightController.text)
                        : null;
                    int? quality = qualityController.text.isNotEmpty
                        ? int.parse(qualityController.text)
                        : null;
                    onPick(width, height, quality);
                    Navigator.of(context).pop();
                  }),
            ],
          );
        });
  }
}

typedef void OnPickImageCallback(
    double? maxWidth, double? maxHeight, int? quality);

class AspectRatioVideo extends StatefulWidget {
  AspectRatioVideo(this.controller);

  final VideoPlayerController? controller;

  @override
  AspectRatioVideoState createState() => AspectRatioVideoState();
}

class AspectRatioVideoState extends State<AspectRatioVideo> {
  VideoPlayerController? get controller => widget.controller;
  bool initialized = false;

  void _onVideoControllerUpdate() {
    if (!mounted) {
      return;
    }
    if (initialized != controller!.value.isInitialized) {
      initialized = controller!.value.isInitialized;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    controller!.addListener(_onVideoControllerUpdate);
  }

  @override
  void dispose() {
    controller!.removeListener(_onVideoControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (initialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: controller!.value.aspectRatio,
          child: VideoPlayer(controller!),
        ),
      );
    } else {
      return Container();
    }
  }
}
