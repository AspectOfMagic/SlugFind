# SlugFind

## Description
A community based Classroom Locator that allows students to help other students find their classes, discussion sessions, and lab sessions by pinpointing exact room locations on the UCSC map with a short description. Available on Android & iOS.

## Team
- Product Owner/Developer: Jason Wu
- Developer: Cadan Crowell
- Developer: Christian Perez
- Developer: Hasan Turkoz
- Developer: Timothy Park

## Deliverables
#### Release Summary, Test Plan & Report, & Release Plan
- [Release Plan](docs/Release-Plan.pdf)
- [Test Plan & Report](docs/Test%20Plan%20and%20Report.pdf)
- [Release Summary](docs/Release-Summary.pdf)

#### Sprint Plans
- [Sprint 1 Plan](docs/Sprint-1-Plan.pdf)
- [Sprint 2 Plan](docs/Sprint-2-Plan.pdf)
- [Sprint 3 Plan](docs/Sprint-3-Plan.pdf)
- [Sprint 4 Plan](docs/Sprint-4-Plan.pdf)

#### Sprint Reports
- [Sprint 1 Report](docs/Sprint-1-Report.pdf)
- [Sprint 2 Report](docs/Sprint-2-Report.pdf)
- [Sprint 3 Report](docs/Sprint-3-Report.pdf)
- [Sprint 4 Report](docs/Sprint-4-Report.pdf)

## Project Tools
- Flutter SDK
- Google Maps API
- Firebase
- Android Studio
- Xcode

## Features
#### Place Markers
Once you find the location on the map where you want to place a marker, you will then long press on the exact spot and a popup window will open. You will then type in the name of the classroom and any additional information then click submit.
#### Search Bar
The user can use the search bar to search markers and current Google Map locations. Markers will show up first in the search bar and shows previews for markers.
#### Local vs Global Markers
On the top right, there is a switch which show only the markers the certain user has placed (local) and the other side of the switch is the global markers where every marker that anyone places is visible.
#### Location Bounds
Through the search bar and placing markers, both will be only in the UC Santa Cruz campus, nothing outside of it.
#### Report Inaccurate Markers
If there is a marker that is inaccurately showing a classroom, a user can click the report button on the marker and an admin will manually check the marker and delete it if necessary.
#### Light & Dark Mode
On the right part of the search bar, there is a button that a user can click if they want to make the app light or dark mode.

## Installation

### Prerequisites
Software & Tools
- Flutter (3.19.6 or higher)
- Android Simulator (34 or higher)
- iOS Simulator (17.5 or higher)
- Google Maps API key

*Simulators used for this project:* 
- *Google Pixel 7* 
- *Google Pixel 8*
- *iPhone 15*

### Steps
1. Clone the repository:
    ```bash
    git clone https://github.com/AspectOfMagic/SlugFind
    ```
2. Navigate to the project directory:
    ```bash
    cd SlugFind/slug_find_app
    ```
3. Install dependencies:
    ```bash
    flutter pub get
    ```
4. Update dependencies:
    ```bash
    flutter pub outdated
    ```

### Running the Project
To run SlugFind, use:
```bash
flutter run
```