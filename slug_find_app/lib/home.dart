import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'request.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';



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
  MarkerId markedId = const MarkerId('empty');

  void _onMapCreated(GoogleMapController mapcontroller) {
    mapController = mapcontroller;

    loadMarkers().then((loadedMarkers) {
      setState(() {
        markers = loadedMarkers;
      });
    });
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

  void _markMarker(MarkerId id, Marker marker) {
    if (markedId != const MarkerId('empty')) {
      Marker? selectedMarker = markers[markedId];
      if (selectedMarker != null) {
        markers[markedId] = selectedMarker.copyWith(
          iconParam: BitmapDescriptor.defaultMarker,
        );
      }
    }
    
    Marker updatedMarker = marker.copyWith(
      iconParam: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    markedId = id;
    markers[id] = updatedMarker;
    
    setState(() {});
  }
  
  void _zoomInOnMarker(Marker marker) async {
    await mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: marker.position,
          zoom: 17,
        ),
      ),
    );
  }

  bool _checkMarkers(String key) {
    for (var entry in markers.entries) {
      var marker = entry.value;
      if (marker.infoWindow.title == key) {
        _markMarker(entry.key, marker);
        _zoomInOnMarker(marker);
        return true;
      }
    }
    return false;
  }

  /*
  void _sendtoServer(String input) async {
    var data = await putMarker(Uri.http('127.0.0.1:8090', 'marker'),
        jsonEncode({'user-input': input}));
    var decodedData = jsonDecode(data);
    print(decodedData['message']);
  }
  */

  void _updateLocationFromSearch(String search) async {
    try {
      List<Location> locations = await locationFromAddress(search);
      const double minLatitude = 36.9791;
      const double maxLatitude = 37.0039;
      const double minLongitude = -122.0733;
      const double maxLongitude = -122.0377;

      if (locations.isNotEmpty) {

        double latitude = locations[0].latitude;
        double longitude = locations[0].longitude;

        if (latitude >= minLatitude && latitude <= maxLatitude && longitude >= minLongitude && longitude <= maxLongitude) {
          mapController.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(latitude, longitude),
                zoom: 17,
              ),
            ),
          );
        } else {
          _showDialog(context, "Location is outside of the UCSC campus. Please try again.");
        }
      }
    } catch (e) {
      print('Failed to find location: $e');
    }
  }

  void _showDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Notification"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
      final String title = result['title'] ?? 'Default Title';
      final String snippet = result['snippet'] ?? 'No additional info';

      final MarkerId markerId = MarkerId(latlang.toString());
      Marker marker = Marker(
        markerId: markerId,
        draggable: true,
        position: latlang,
        infoWindow: InfoWindow(
          title: title,
          snippet: snippet,
        ),
        icon: BitmapDescriptor.defaultMarker,
        onTap: () => _showMarkerDetails(markerId, title, snippet),

      );

      setState(() {
        markers[markerId] = marker;
      });

      saveMarker(latlang, title, snippet);
    }
  }

  void _showMarkerDetails(MarkerId markerId, String title, String snippet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(snippet),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              deleteMarker(markerId);
            },
            child: Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteMarker(MarkerId markerId) async {
    await FirebaseFirestore.instance.collection('markers').doc(markerId.value).delete();
    setState(() {
      markers.remove(markerId);
    });
  }

  Future<void> saveMarker(LatLng position, String title, String snippet) async {
    var firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      CollectionReference markers = FirebaseFirestore.instance.collection('markers');
      await markers.add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'title': title,
        'snippet': snippet,
        'userId': firebaseUser.uid,
      });
    }
    loadMarkers().then((loadedMarkers) {
      setState(() {
        markers = loadedMarkers;
      });
    });
  }

  Future<Map<MarkerId, Marker>> loadMarkers() async {
    CollectionReference markersCollection = FirebaseFirestore.instance.collection('markers');
    QuerySnapshot querySnapshot = await markersCollection.get();

    Map<MarkerId, Marker> loadedMarkers = {};
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      final markerId = MarkerId(doc.id);
      final data = doc.data() as Map<String, dynamic>;

      loadedMarkers[markerId] = Marker(
        markerId: markerId,
        position: LatLng(data['latitude'], data['longitude']),
        infoWindow: InfoWindow(
          title: data['title'] ?? 'Untitled',
          snippet: data['snippet'] ?? '',
        ),
        icon: BitmapDescriptor.defaultMarker,
        onTap: () {
          _showMarkerDetails(markerId, data['title'], data['snippet']);
        },
      );
    }
    return loadedMarkers;
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
                  padding: const EdgeInsets.only(bottom: 0),
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _center,
                      zoom: currentZoom,
                    ),
                    zoomControlsEnabled: false,
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
                      heroTag: 'zoomInButton',
                      onPressed: _zoomIn,
                      child: const Icon(Icons.zoom_in),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                      heroTag: 'zoomOutButton',
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
                              searchHistory = searchHistory.reversed.toSet().toList();
                              controller.closeView(controller.text);
                              if (!_checkMarkers(controller.text)) {
                                _updateLocationFromSearch(controller.text);
                              }
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
