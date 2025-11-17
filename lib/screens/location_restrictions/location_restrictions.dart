import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stelacom_check/app-services/logout_service.dart';
import 'package:stelacom_check/constants.dart';
import 'package:stelacom_check/controllers/location_restriction_controller.dart';
import 'package:stelacom_check/screens/home/first_screen.dart';
import 'package:stelacom_check/screens/menu/about_us.dart';
import 'package:stelacom_check/screens/menu/contact_us.dart';
import 'package:stelacom_check/screens/menu/help.dart';
import 'package:stelacom_check/screens/menu/terms_conditions.dart';
import 'package:stelacom_check/responsive.dart';
import '../../components/utils/custom_error_dialog.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ValidateLocationRestrictionsScreen extends StatelessWidget {
  final int index3;

  ValidateLocationRestrictionsScreen(this.index3);

  // Side menu options

  List<String> _getMenuOptions() {
    return ['Help', 'About Us', 'Contact Us', 'T & C', 'Log Out'];
  }

  void _handleMenuAction(String choice, BuildContext context) {
    final options = _getMenuOptions();
    // Handle navigation using GetX
    if (choice == options[0]) {
      Get.to(() => HelpScreen(index3: index3));
    } else if (choice == options[1]) {
      Get.to(() => AboutUs(index3: index3));
    } else if (choice == options[2]) {
      Get.to(() => ContactUs(index3: index3));
    } else if (choice == options[3]) {
      Get.to(() => TermsAndConditions(index3: index3));
    } else if (choice == options[4]) {
      LogoutService.logoutWithOptions(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize controller - GetX will handle its lifecycle
    final controller = Get.put(LocationRestrictionsController());
    Size size = MediaQuery.of(context).size;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, dynamic2) {
        if (didPop) {
          return;
        }
        Get.back();
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: appbarBgColor,
          toolbarHeight:
              Responsive.isMobileSmall(context) ||
                  Responsive.isMobileMedium(context) ||
                  Responsive.isMobileLarge(context)
              ? 40
              : Responsive.isTabletPortrait(context)
              ? 80
              : 90,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // App Logo
              SizedBox(
                width:
                    Responsive.isMobileSmall(context) ||
                        Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                    ? 90.0
                    : Responsive.isTabletPortrait(context)
                    ? 150
                    : 170,
                height:
                    Responsive.isMobileSmall(context) ||
                        Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                    ? 40.0
                    : Responsive.isTabletPortrait(context)
                    ? 120
                    : 100,
                child: Image.asset(
                  'assets/images/iCheck_logo_2024.png',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: size.width * 0.25),
              // Company Logo - Using Obx to listen to userObj changes
              Obx(
                () => SizedBox(
                  width:
                      Responsive.isMobileSmall(context) ||
                          Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 90.0
                      : Responsive.isTabletPortrait(context)
                      ? 150
                      : 170,
                  height:
                      Responsive.isMobileSmall(context) ||
                          Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 40.0
                      : Responsive.isTabletPortrait(context)
                      ? 120
                      : 100,
                  child: controller.userObj.value != null
                      ? CachedNetworkImage(
                          imageUrl:
                              controller.userObj.value!['CompanyProfileImage'],
                          placeholder: (context, url) => Text("..."),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        )
                      : Text(""),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            PopupMenuButton<String>(
              color: Colors.white,
              onSelected: (choice) => _handleMenuAction(choice, context),
              itemBuilder: (BuildContext context) {
                return _getMenuOptions().map((String choice) {
                  return PopupMenuItem<String>(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          Responsive.isMobileSmall(context) ||
                              Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 15
                          : 20,
                      vertical:
                          Responsive.isMobileSmall(context) ||
                              Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 5
                          : 10,
                    ),
                    value: choice,
                    child: Text(
                      choice,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: Responsive.isMobileSmall(context)
                            ? 15
                            : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                            ? 17
                            : Responsive.isTabletPortrait(context)
                            ? 25
                            : 25,
                      ),
                    ),
                  );
                }).toList();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: screenHeadingColor,
                      size: Responsive.isMobileSmall(context)
                          ? 20
                          : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                          ? 24
                          : Responsive.isTabletPortrait(context)
                          ? 31
                          : 35,
                    ),
                    onPressed: () {
                      Get.back();
                    },
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      "Location Restrictions",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: screenHeadingColor,
                        fontSize: Responsive.isMobileSmall(context)
                            ? 22
                            : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                            ? 25
                            : Responsive.isTabletPortrait(context)
                            ? 32
                            : 32,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(flex: 1, child: Text("")),
                ],
              ),
            ),
            SizedBox(height: 10),
            _buildBody(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LocationRestrictionsController controller,
  ) {
    return Obx(() {
      // Check if should show alert
      if (controller.shouldShowAlert.value &&
          controller.shouldShowLocationAlert() &&
          controller.userLocationRestrictions.isNotEmpty) {
        controller.shouldShowAlert.value = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.dialog(
            CustomErrorDialog(
              title: 'Error!',
              message:
                  'Sorry. The system cannot find out the location inside the assigned radius. Please contact the iCheck administrator and ask to access the system using the allow by pass option.',
              onOkPressed: () {
                Get.back();
                Get.off(() => HomeScreen(index2: 0));
              },
              iconData: Icons.not_listed_location,
            ),
            barrierDismissible: false,
          );
        });
      }

      return Container(
        height: MediaQuery.of(context).size.width * 1.54,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          itemCount: controller.userLocationRestrictions.length,
          itemBuilder: (context, index) {
            final location = controller.userLocationRestrictions[index];
            final locationDistance = location['Distance'];
            final allowByPass = location['AllowedByPass'];
            final locationName = location['Name'];
            final distanceText = location['DistanceText'];

            return GestureDetector(
              onTap: () => _showLocationMap(
                context,
                location,
                controller.currentPosition.value,
              ),
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                  border: locationDistance == null || locationDistance > 0
                      ? null
                      : Border.all(color: Colors.green, width: 2),
                ),
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      _buildLocationIcon(
                        context,
                        locationDistance,
                        allowByPass,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locationName ?? '',
                              style: TextStyle(
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 14
                                    : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                    ? 16
                                    : Responsive.isTabletPortrait(context)
                                    ? 20
                                    : 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              distanceText ?? 'Distance checking...',
                              style: TextStyle(
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 12
                                    : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                    ? 13
                                    : Responsive.isTabletPortrait(context)
                                    ? 18
                                    : 20,
                                color: distanceText == null
                                    ? Colors.red
                                    : distanceText.contains("Inside now")
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildForwardButton(
                        context,
                        controller,
                        index,
                        locationDistance,
                        allowByPass,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildLocationIcon(
    BuildContext context,
    dynamic locationDistance,
    dynamic allowByPass,
  ) {
    bool isInside = locationDistance != null && locationDistance <= 0;
    bool hasBypass = allowByPass != null && allowByPass == 1;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasBypass
            ? (isInside ? Colors.green[200] : Colors.orange[200])
            : (isInside ? Colors.green[200] : Colors.grey[200]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isInside ? Icons.location_on : Icons.location_off,
        size: Responsive.isMobileSmall(context)
            ? 22
            : Responsive.isMobileMedium(context) ||
                  Responsive.isMobileLarge(context)
            ? 25
            : Responsive.isTabletPortrait(context)
            ? 28
            : 30,
        color: hasBypass
            ? (isInside ? Colors.white : Colors.grey[50])
            : (isInside ? Colors.white : Colors.grey[600]),
      ),
    );
  }

  Widget _buildForwardButton(
    BuildContext context,
    LocationRestrictionsController controller,
    int index,
    dynamic locationDistance,
    dynamic allowByPass,
  ) {
    bool isInside = locationDistance != null && locationDistance <= 0;
    bool hasBypass = allowByPass != null && allowByPass == 1;
    bool canProceed = isInside || hasBypass;

    return GestureDetector(
      onTap: () {
        if (canProceed || hasBypass) {
          controller.handleLocationTap(index);
        }
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasBypass
              ? (isInside ? Colors.green[200] : Colors.orange[200])
              : (canProceed ? Colors.green[200] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          hasBypass
              ? Icons.arrow_forward_ios
              : (canProceed ? Icons.arrow_forward_ios : Icons.block),
          size: Responsive.isMobileSmall(context)
              ? 18
              : Responsive.isMobileMedium(context) ||
                    Responsive.isMobileLarge(context)
              ? 20
              : Responsive.isTabletPortrait(context)
              ? 25
              : 28,
          color: hasBypass
              ? Colors.grey[100]
              : (canProceed ? Colors.grey[100] : Colors.grey[600]),
        ),
      ),
    );
  }

  void _showLocationMap(
    BuildContext context,
    dynamic location,
    Position? currentPosition,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationMapSheet(
        location: location,
        currentPosition: currentPosition,
      ),
    );
  }
}

class _LocationMapSheet extends StatelessWidget {
  final dynamic location;
  final Position? currentPosition;

  const _LocationMapSheet({
    required this.location,
    required this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      location['Name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formatDistanceText(location['DistanceText']),
                      style: TextStyle(
                        color: (location['DistanceText']).contains("Inside now")
                            ? Colors.green
                            : Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.red[800],
                          size: 30,
                        ),
                        Text(
                          "Assigned Location",
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.blue[800],
                          size: 30,
                        ),
                        Text(
                          "Your Current Location",
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _getCenterPosition(),
                    zoom: _getAppropriateZoomLevel(),
                  ),
                  markers: _createMarkers(),
                  circles: _createCircles(),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  trafficEnabled: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String formatDistanceText(String distanceText) {
    if (distanceText.contains("Inside now")) {
      return "Inside Now";
    } else {
      RegExp regex = RegExp(r'(\d+(\.\d+)?\s*KM to go)');
      Match? match = regex.firstMatch(distanceText);
      return match != null ? match.group(1)! : distanceText;
    }
  }

  Set<Marker> _createMarkers() {
    Set<Marker> markers = {};

    markers.add(
      Marker(
        markerId: MarkerId(location['Name']),
        position: LatLng(
          double.parse(location['InLat']),
          double.parse(location['InLong']),
        ),
        infoWindow: InfoWindow(
          title: location['Name'],
          snippet: '${location['Radius'] / 1000} KM radius',
        ),
      ),
    );

    if (currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            currentPosition!.latitude,
            currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Current Location'),
        ),
      );
    }

    return markers;
  }

  Set<Circle> _createCircles() {
    return {
      Circle(
        circleId: CircleId(location['Name']),
        center: LatLng(
          double.parse(location['InLat']),
          double.parse(location['InLong']),
        ),
        radius: location['Radius'],
        fillColor: (location['DistanceText']).contains("Inside now")
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        strokeColor: (location['DistanceText']).contains("Inside now")
            ? Colors.green
            : Colors.red,
        strokeWidth: 2,
      ),
    };
  }

  LatLng _getCenterPosition() {
    if (currentPosition == null) {
      return LatLng(
        double.parse(location['InLat']),
        double.parse(location['InLong']),
      );
    }

    return LatLng(
      (currentPosition!.latitude + double.parse(location['InLat'])) / 2,
      (currentPosition!.longitude + double.parse(location['InLong'])) / 2,
    );
  }

  double _getAppropriateZoomLevel() {
    if (currentPosition == null) {
      return 11;
    }

    double distanceInMeters = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      double.parse(location['InLat']),
      double.parse(location['InLong']),
    );

    if (distanceInMeters < 100) return 17;
    if (distanceInMeters < 1000) return 15;
    if (distanceInMeters < 5000) return 13;
    if (distanceInMeters < 10000) return 12;
    return 9.5;
  }
}
