import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _darkMapStyle;
  String? _lightMapStyle;
  bool isDark = false;
  var searchHistory = [];
  List<String> allSuggestions = [];
  final SearchController controller = SearchController();
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(36.9905, -122.0584);
  double currentZoom = 15;
  MarkerId markedId = const MarkerId('empty');
  bool _showGlobalMarkers = false;
  int selectedFloorLevel = 0;
  final List<String> developerIds = [
    'QEUR6jvclhQUysCKuYGGSCxckLi2',
    'QcKnTZbGjBX1zdNejcqtHSxGtyl2',
    '8BheQrwzqEakcOVroZ82AfM9Yzp2',
    'Dcxrvm2X4AQ3I6tDcjip9pNzcTv2',
    'Sw2b0lZT9LOzqKL8nDnxI5mJR733'
  ];
  bool isDeveloper = false;
  List<Map<String, dynamic>> reports = [];
  final List<String> listFloorNums = <String>['B', '1', '2', '3', '4', '5'];

  @override
  void initState() {
    super.initState();
    _loadMapStyles();
    _loadMarkers();
  }

  Future<void> _loadMapStyles() async {
    _darkMapStyle = await rootBundle.loadString('assets/dark_map_style.json');
    _lightMapStyle = await rootBundle.loadString('assets/light_map_style.json');
  }

  Future<void> _loadMarkers() async {
    final loadedMarkers =
        await _fetchMarkers(_showGlobalMarkers, selectedFloorLevel);
    setState(() {
      markers = loadedMarkers;
      allSuggestions = markers.values
          .map((marker) => marker.infoWindow.title)
          .whereType<String>()
          .toList();
    });
  }

  void _onMapCreated(GoogleMapController mapcontroller) {
    mapController = mapcontroller;
    _setMapStyle();
    _loadMarkers();
    _checkIfDeveloper();
  }

  void _setMapStyle() {
    if (isDark) {
      mapController.setMapStyle(_darkMapStyle);
    } else if (!isDark) {
      mapController.setMapStyle(_lightMapStyle);
    }
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

  void _markMarker(MarkerId id, Marker marker) async {
    if (markedId != const MarkerId('empty')) {
      Marker? selectedMarker = markers[markedId];
      if (selectedMarker != null) {
        String? userId = await _getUserIDForMarker(markedId);
        bool sameUser = FirebaseAuth.instance.currentUser?.uid == userId;
        if (sameUser) {
          markers[markedId] = selectedMarker.copyWith(
            iconParam:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          );
        } else {
          markers[markedId] = selectedMarker.copyWith(
            iconParam: BitmapDescriptor.defaultMarker,
          );
        }
      }
    }

    Marker updatedMarker = marker.copyWith(
      iconParam:
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    markedId = id;
    markers[id] = updatedMarker;

    setState(() {});
  }

  void _zoomInOnMarker(Marker marker) async {
    await mapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: marker.position,
          zoom: 17,
        ),
      ),
    );
    currentZoom = 17;
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

  void _updateLocationFromSearch(String search) async {
    try {
      String searchStr = search;

      if (searchStr.isNotEmpty) {
        searchStr = searchStr + " UCSC";
      }

      List<Location> locations = await locationFromAddress(searchStr);
      const double minLatitude = 36.9772;
      const double maxLatitude = 37.0039;
      const double minLongitude = -122.0703;
      const double maxLongitude = -122.049;

      if (locations.isNotEmpty) {
        double latitude = locations[0].latitude;
        double longitude = locations[0].longitude;

        if (latitude >= minLatitude &&
            latitude <= maxLatitude &&
            longitude >= minLongitude &&
            longitude <= maxLongitude) {
          mapController.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(latitude, longitude),
                zoom: 17,
              ),
            ),
          );
          currentZoom = 17;
        } else {
          _showDialog(context,
              "Location is outside of the UCSC campus. Please try again.");
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
        String floor = listFloorNums.first;

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
                const SizedBox(height: 16.0),
                const Text('Floor Number:'),
                DropdownMenu<String>(
                  initialSelection: listFloorNums.first,
                  onSelected: (value) {
                    floor = value!;
                  },
                  dropdownMenuEntries: listFloorNums
                      .map<DropdownMenuEntry<String>>((String value) {
                    return DropdownMenuEntry<String>(
                        value: value, label: value);
                  }).toList(),
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
                Navigator.of(context)
                    .pop({'title': title, 'snippet': snippet, 'floor': floor});
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future _addMarkerLongPressed(LatLng latlang) async {
    const double minLatitude = 36.9772;
    const double maxLatitude = 37.0039;
    const double minLongitude = -122.0703;
    const double maxLongitude = -122.049;

    if (latlang.latitude >= minLatitude &&
        latlang.latitude <= maxLatitude &&
        latlang.longitude >= minLongitude &&
        latlang.longitude <= maxLongitude) {
      final result = await popup();

      if (result != null) {
        final String title = result['title'] ?? 'Default Title';
        final String snippet = result['snippet'] ?? 'No additional info';
        final String floor = result['floor'] ?? '1';
        final String newSnippet = 'Info: $snippet\nFloor: $floor';
        final MarkerId markerId = MarkerId(latlang.toString());
        bool markerExists = markers.values.any((marker) =>
            (marker.infoWindow.title?.toLowerCase() ?? '') ==
            (title.toLowerCase()));

        if (!markerExists) {
          Marker marker = Marker(
            markerId: markerId,
            draggable: true,
            position: latlang,
            infoWindow: InfoWindow(
              title: title,
              snippet: newSnippet,
            ),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            onTap: () => _showMarkerDetails(markerId, title, newSnippet),
          );

          setState(() {
            markers[markerId] = marker;
          });

          _saveMarker(latlang, title, newSnippet, floor);
        } else {
          _showDialog(context,
              "A marker with that name already exists. Please try again.");
        }
      }
    } else {
      _showDialog(context,
          "Marker location is outside of the UCSC campus. Please try again.");
    }
  }

  void _showMarkerDetails(MarkerId markerId, String title, String snippet) {
    _getUserIDForMarker(markerId).then((userId) {
      bool canDelete = FirebaseAuth.instance.currentUser?.uid == userId;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(snippet),
          actions: <Widget>[
            if (canDelete)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteMarker(markerId);
                },
                child: Text('Delete'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showReportDialog(markerId);
              },
              child: Text('Report'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _showReportDialog(MarkerId markerId) async {
    TextEditingController reasonController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Report Marker'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Enter the reason for reporting this marker:'),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(hintText: 'Reason'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Send'),
              onPressed: () {
                String reason = reasonController.text;
                Navigator.of(context).pop();
                _reportMarker(markerId, reason);
              },
            ),
          ],
        );
      },
    );
  }

  Future<String?> _getUserIDForMarker(MarkerId markerId) async {
    try {
      DocumentSnapshot markerDocument = await FirebaseFirestore.instance
          .collection('markers')
          .doc(markerId.value)
          .get();
      if (markerDocument.exists) {
        Map<String, dynamic>? data =
            markerDocument.data() as Map<String, dynamic>?;
        return data?['userId'] as String?;
      }
    } catch (e) {
      print('Error fetching user ID: $e');
    }
    return null;
  }

  Future<void> _reportMarker(MarkerId markerId, String reason) async {
    var firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        String? userId = await _getUserIDForMarker(markerId);
        if (userId == null) {
          print('User ID not found for marker: $markerId');
          return;
        }

        DocumentSnapshot markerDocument = await FirebaseFirestore.instance
            .collection('markers')
            .doc(markerId.value)
            .get();
        Map<String, dynamic> markerData =
            markerDocument.data() as Map<String, dynamic>;

        await FirebaseFirestore.instance.collection('reports').add({
          'reportedMarkerId': markerId.value,
          'markerTitle': markerData['title'],
          'markerSnippet': markerData['snippet'],
          'reportedBy': firebaseUser.uid,
          'reportedUserId': userId,
          'reason': reason,
        });
      } catch (e) {
          _showDialog(context,
              "Report submission failed. Please try again.");
        }      
    }
  }

  Future<void> _deleteMarker(MarkerId markerId) async {
    await FirebaseFirestore.instance
        .collection('markers')
        .doc(markerId.value)
        .delete();
    setState(() {
      markers.remove(markerId);
    });
  }

  Future<void> _saveMarker(
      LatLng position, String title, String snippet, String floor) async {
    var firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      CollectionReference markers =
          FirebaseFirestore.instance.collection('markers');
      await markers.add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'title': title,
        'snippet': snippet,
        'userId': firebaseUser.uid,
        'floor': floor, // Add the floor parameter
      });
    }
    _loadMarkers();
  }

  Future<Map<MarkerId, Marker>> _fetchMarkers(
      bool isGlobal, int selectedFloorLevel) async {
    CollectionReference markersCollection =
        FirebaseFirestore.instance.collection('markers');
    Query query = isGlobal
        ? markersCollection
        : markersCollection.where('userId',
            isEqualTo: FirebaseAuth.instance.currentUser?.uid);

    // Filter markers based on the selected floor level
    if (selectedFloorLevel != 0) {
      String floorValue =
          selectedFloorLevel == 1 ? 'B' : (selectedFloorLevel - 1).toString();
      query = query.where('floor', isEqualTo: floorValue);
    }

    QuerySnapshot querySnapshot = await query.get();
    Map<MarkerId, Marker> loadedMarkers = {};
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      final markerId = MarkerId(doc.id);
      final data = doc.data() as Map<String, dynamic>;
      final userId = data['userId'] as String?;
      final isCurrentUser = userId == FirebaseAuth.instance.currentUser?.uid;

      loadedMarkers[markerId] = Marker(
        markerId: markerId,
        position: LatLng(data['latitude'], data['longitude']),
        infoWindow: InfoWindow(
          title: data['title'] ?? 'Untitled',
          snippet: data['snippet'] ?? '',
        ),
        icon: isCurrentUser
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
            : BitmapDescriptor.defaultMarker,
        onTap: () {
          _showMarkerDetails(markerId, data['title'], data['snippet']);
        },
      );
    }
    return loadedMarkers;
  }

  Future<void> _checkIfDeveloper() async {
    var firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && developerIds.contains(firebaseUser.uid)) {
      setState(() {
        isDeveloper = true;
      });
      await _fetchReports();
    }
  }

  Future<void> _fetchReports() async {
    CollectionReference reportsCollection =
        FirebaseFirestore.instance.collection('reports');
    QuerySnapshot querySnapshot = await reportsCollection.get();
    Map<String, int> reportCounts = {};

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final markerId = data['reportedMarkerId'];
      if (reportCounts.containsKey(markerId)) {
        reportCounts[markerId] = reportCounts[markerId]! + 1;
      } else {
        reportCounts[markerId] = 1;
      }
    }

    List<Map<String, dynamic>> aggregatedReports = [];
    for (String markerId in reportCounts.keys) {
      final query = await FirebaseFirestore.instance
          .collection('markers')
          .doc(markerId)
          .get();
      if (query.exists) {
        final markerData = query.data() as Map<String, dynamic>;
        aggregatedReports.add({
          'markerId': markerId,
          'markerTitle': markerData['title'],
          'markerSnippet': markerData['snippet'],
          'count': reportCounts[markerId],
        });
      }
    }

    setState(() {
      reports = aggregatedReports;
    });

    if (reports.isNotEmpty) {
      _showReportsDialog();
    }
  }

  void _showReportsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reports'),
        content: SingleChildScrollView(
          child: Column(
            children: reports.map((report) {
              return ListTile(
                title: Text(report['markerTitle']),
                subtitle: Text(
                    'Description: ${report['markerSnippet']}\nReports: ${report['count']}'),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
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
                // Add the floor level buttons

                Row(
                  children: [
                    Text(_showGlobalMarkers ? 'Global' : 'Local'),
                    Switch(
                      value: _showGlobalMarkers,
                      onChanged: (value) {
                        setState(() {
                          _showGlobalMarkers = value;
                          _loadMarkers();
                        });
                      },
                    ),
                  ],
                ),
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
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
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
                  child: Column(children: [
                    SearchAnchor(
                        searchController: controller,
                        viewTrailing: [
                          IconButton(
                              onPressed: () {
                                searchHistory.add(controller.text);
                                searchHistory =
                                    searchHistory.reversed.toSet().toList();
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
                        builder: (BuildContext context,
                            SearchController controller) {
                          return SearchBar(
                              controller: controller,
                              padding:
                                  const MaterialStatePropertyAll<EdgeInsets>(
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
                                          _setMapStyle();
                                        });
                                      },
                                      icon: const Icon(Icons.wb_sunny_outlined),
                                      selectedIcon: const Icon(
                                          Icons.brightness_2_outlined),
                                    ))
                              ]);
                        },
                        suggestionsBuilder: (BuildContext context,
                            SearchController controller) {
                          List<String> filteredSuggestions = [];
                          String query = controller.text.toLowerCase();
                          if (query.isNotEmpty) {
                            filteredSuggestions = allSuggestions
                                .where((suggestion) =>
                                    suggestion.toLowerCase().contains(query))
                                .toList();
                            return List<ListTile>.generate(
                                filteredSuggestions.length, (index) {
                              final item = filteredSuggestions[index];
                              return ListTile(
                                  title: Text(item),
                                  onTap: () {
                                    searchHistory.add(item);
                                    searchHistory =
                                        searchHistory.reversed.toSet().toList();
                                    controller.closeView(item);
                                    _checkMarkers(item);
                                  });
                            });
                          } else {
                            return List<ListTile>.generate(searchHistory.length,
                                (index) {
                              final item = searchHistory[index];
                              return ListTile(
                                  title: Text(item),
                                  onTap: () {
                                    searchHistory.add(item);
                                    searchHistory =
                                        searchHistory.reversed.toSet().toList();
                                    controller.closeView(item);
                                    _checkMarkers(item);
                                  });
                            });
                          }
                        }),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ToggleButtons(
                          onPressed: (int index) {
                            setState(() {
                              selectedFloorLevel = index;
                              _loadMarkers();
                            });
                          },
                          isSelected: List.generate(
                              7, (index) => index == selectedFloorLevel),
                          constraints: const BoxConstraints(
                            minWidth: 30.0,
                            minHeight: 30.0,
                          ),
                          color: Colors.black,
                          selectedColor: Colors.white,
                          fillColor: Colors.blue,
                          borderRadius: BorderRadius.circular(8.0),
                          borderColor: Colors.grey,
                          selectedBorderColor: Colors.blue,
                          children: const [
                            Text('All'),
                            Text('B'),
                            Text('1'),
                            Text('2'),
                            Text('3'),
                            Text('4'),
                            Text('5'),
                          ],
                        ),
                      ],
                    ),
                  ]))
            ])));
  }
}
