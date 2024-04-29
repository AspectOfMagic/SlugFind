import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

    State<HomeScreen> createState() => _HomeScreenState();
}
  
class _HomeScreenState extends State<HomeScreen> {
  bool isDark = false;
  var searchHistory = [];
  final SearchController controller = SearchController();
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(36.9905, -122.0584);
  
  void _onMapCreated(GoogleMapController mapcontroller) {
      mapController = mapcontroller;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SlugFind'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<ProfileScreen>(
                  builder: (context) => ProfileScreen(
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
                  ),
                ),
              );
            },
          )
        ],
        automaticallyImplyLeading: false,
      ),
        body: Stack(
          children: <Widget>[ 
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 15,
                ),
                markers: {
                  const Marker(
                    markerId: MarkerId("UCSC"),
                    position: LatLng(36.99, -122.058),
                    infoWindow: InfoWindow(
                      title: "University of California, Santa Cruz",
                      snippet: "Go Slugs",
                    ),
                  )
                }
              )
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
                      _updateLocationFromSearch(controller.text);
                    }, 
                    icon: const Icon(Icons.search)
                  ),
                  IconButton(
                    onPressed: () {
                      controller.clear();
                    }, 
                    icon: const Icon(Icons.clear)
                  )
                ],
                builder: (BuildContext context, SearchController controller) {
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
                    trailing: <Widget> [
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
                          selectedIcon: const Icon(Icons.brightness_2_outlined), 
                        )
                      )
                    ]
                  );
                }, 
                suggestionsBuilder: (BuildContext context, SearchController controller) {
                  return List<ListTile>.generate(
                    searchHistory.length, 
                    (index) {
                      final item = searchHistory[index];
                      return ListTile(
                        title: Text(item),
                        onTap: () {
                          setState(() {
                            controller.closeView(item);
                          });
                        }
                      );
                    }
                  );
                }
              )
            )
          ]
        )
      );
    }
  }


