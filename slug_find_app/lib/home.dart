import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'request.dart';
import 'dart:convert';

Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isDark = false;
  var searchHistory = [];
  final SearchController controller = SearchController();
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(36.9905, -122.0584);
  double currentZoom = 15;


  void _onMapCreated(GoogleMapController mapcontroller) {
    mapController = mapcontroller;
  }

  void _zoomIn() {
    setState(() {
      currentZoom += 1;
      mapController.animateCamera(
        CameraUpdate.zoomTo(currentZoom),
      );
    });
  }

  void _zoomOut() {
    setState(() {
      currentZoom -= 1;
      mapController.animateCamera(
        CameraUpdate.zoomTo(currentZoom),
      );
    });
  }

  void _sendtoServer(String input) async {
    var data = await putMarker(Uri.http('127.0.0.1:8090', 'marker'),
        jsonEncode({'user-input': input}));
    var decodedData = jsonDecode(data);
    print(decodedData['message']);
  }

  void _updateLocationFromSearch(String search) async {
    try {
      List<Location> locations = await locationFromAddress(search);
      if (locations.isNotEmpty) {
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(locations[0].latitude, locations[0].longitude),
              zoom: 19,
            ),
          ),
        );
      }
    } catch (e) {
      print('Failed to find location: $e');
    }
  }

  Future<Map<String, String>?> popup() async {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        String title = '';
        String snippet = '';

        return AlertDialog(
          title: const Text('Marker info'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (value) {
                    title = value;
                  },
                  decoration: InputDecoration(hintText: 'Location name'),
                ),
                SizedBox(height: 16.0),
                TextField(
                  onChanged: (value) {
                    snippet = value;
                  },
                  decoration: InputDecoration(hintText: 'Additional info'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({'title': title, 'snippet': snippet});
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future _addMarkerLongPressed(LatLng latlang) async {
    final result = await popup();

    if (result != null) {
      final MarkerId markerId = MarkerId("Random_ID");
      Marker marker = Marker(
        markerId: markerId,
        draggable: true,
        position: latlang,
        infoWindow: InfoWindow(
          title: result['title'],
          snippet: result['snippet'],
        ),
        icon: BitmapDescriptor.defaultMarker,
      );

      setState(() {
        markers[markerId] = marker;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = ThemeData(
        useMaterial3: true,
        brightness: isDark ? Brightness.dark : Brightness.light);
    return MaterialApp(
        theme: themeData,
        home: Scaffold(
            appBar: AppBar(
              title: const Text('SlugFind'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<ProfileScreen>(
                          builder: (context) => Theme(
                              data: ThemeData(
                                  useMaterial3: true,
                                  brightness: isDark
                                      ? Brightness.dark
                                      : Brightness.light),
                              child: ProfileScreen(
                                appBar: AppBar(
                                  title: const Text('User Profile'),
                                ),
                                actions: [
                                  SignedOutAction((context) {
                                    Navigator.of(context).pop();
                                  })
                                ],
                                children: [
                                  const Divider(),
                                  Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: Image.asset('assets/slug1.jpg'),
                                    ),
                                  ),
                                ],
                              ))),
                    );
                  },
                )
              ],
              automaticallyImplyLeading: false,
            ),
            body: Stack(children: <Widget>[
              Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _center,
                      zoom: currentZoom,
                    ),
                    compassEnabled: true,
                    tiltGesturesEnabled: false,
                    onLongPress: (latlang) {
                      _addMarkerLongPressed(latlang);
                    },
                    markers: Set<Marker>.of(markers.values),
                  )),
              Positioned(
                right: 10,
                bottom: 100,
                child: Column(
                  children: <Widget>[
                    FloatingActionButton(
                      onPressed: _zoomIn,
                      child: const Icon(Icons.zoom_in),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                      onPressed: _zoomOut,
                      child: const Icon(Icons.zoom_out),
                    ),
                  ],
                ),
              ),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SearchAnchor(
                      searchController: controller,
                      viewTrailing: [
                        IconButton(
                            onPressed: () {
                              searchHistory.add(controller.text);
                              searchHistory =
                                  searchHistory.reversed.toSet().toList();
                              controller.closeView(controller.text);
                              _updateLocationFromSearch(controller.text);
                            },
                            icon: const Icon(Icons.search)),
                        IconButton(
                            onPressed: () {
                              controller.clear();
                            },
                            icon: const Icon(Icons.clear))
                      ],
                      builder:
                          (BuildContext context, SearchController controller) {
                        return SearchBar(
                            controller: controller,
                            padding: const MaterialStatePropertyAll<EdgeInsets>(
                              EdgeInsets.symmetric(horizontal: 16.0),
                            ),
                            onTap: () {
                              controller.openView();
                            },
                            onChanged: (_) {
                              controller.openView();
                            },
                            leading: const Icon(Icons.search),
                            trailing: <Widget>[
                              Tooltip(
                                  message: 'Change Brightness Mode',
                                  child: IconButton(
                                    isSelected: isDark,
                                    onPressed: () {
                                      setState(() {
                                        isDark = !isDark;
                                      });
                                    },
                                    icon: const Icon(Icons.wb_sunny_outlined),
                                    selectedIcon:
                                        const Icon(Icons.brightness_2_outlined),
                                  ))
                            ]);
                      },
                      suggestionsBuilder:
                          (BuildContext context, SearchController controller) {
                        return List<ListTile>.generate(searchHistory.length,
                            (index) {
                          final item = searchHistory[index];
                          return ListTile(
                              title: Text(item),
                              onTap: () {
                                setState(() {
                                  controller.closeView(item);
                                });
                              });
                        });
                      }))
            ])));
  }
}
