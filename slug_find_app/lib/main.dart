import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}
  
class _MyAppState extends State<MyApp> {
  bool isDark = false;
  var searchHistory = [];
  final SearchController controller = SearchController();

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light
    );
    
    return MaterialApp(
      theme: themeData,
      home: Scaffold(
        appBar: AppBar(title: const Text('SlugFind')),
        body: Column(
          children: <Widget>[ 
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SearchAnchor(
                searchController: controller,
                viewTrailing: [
                  IconButton(
                    onPressed: () {
                      searchHistory.add(controller.text);
                      controller.closeView(controller.text);
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
      )
    );
  }
}