import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:water_quality_probe/responsive.dart';

import '../screens/scan_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/table_screen.dart';
// import '../screens/visualize_screen.dart';
import '../screens/visualization_screen.dart';
import '../screens/config_screen.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Image.asset("assets/images/Water_Quality_Probe.png"),
          ),
          // DrawerListTile(
          //   title: "Dashboard",
          //   svgSrc: "assets/icons/menu_dashboard.svg",
          //   press: () {
          //     if (!Responsive.isDesktop(context))
          //       Navigator.pop(context);
          //     Navigator.pushReplacement(
          //       context,
          //       MaterialPageRoute(builder: (context) => MainScreen()),
          //       );
          //     },
          // ),
          DrawerListTile(
            title: "Control",
            icon: Icons.question_answer_outlined,
            press: () {
              if (!Responsive.isDesktop(context))
                    Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatScreen()),
              );
            },
          ),
          // DrawerListTile(
          //   title: "Calibración",
          //   //svgSrc: "assets/icons/menu_task.svg",
          //   icon: Icons.bubble_chart_outlined,
          //   press: () {},
          // ),
          DrawerListTile(
            title: "Dispositivos",
            icon: Icons.devices_other_outlined,
            press: () {
              // if (!Responsive.isDesktop(context))
              //   Navigator.pop(context);
              Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ScanScreen()),
              );
            },
          ),
          DrawerListTile(
            title: "Datos",
            svgSrc: "assets/icons/menu_doc.svg",
            // svgSrc: "assets/icons/menu_tran.svg",
            press: () {
              // if (!Responsive.isDesktop(context))
              //   Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TableScreen()),
              );
            },
          ),
          // DrawerListTile(
          //   title: "Documentos",
          //   svgSrc: "assets/icons/menu_doc.svg",
          //   press: () {},
          // ),
          DrawerListTile(
            title: "Gráficos",
            // svgSrc: "assets/icons/menu_profile.svg",
            // icon : Icons.ssid_chart,
            icon : Icons.query_stats,
            press: () {
              // if (!Responsive.isDesktop(context))
              //   Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VisualizeScreen()),
              );
            },
          ),
          DrawerListTile(
            title: "Configuración",
            svgSrc: "assets/icons/menu_setting.svg",
            press: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ConfigScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}


class DrawerListTile extends StatelessWidget {
  const DrawerListTile({
    Key? key,
    required this.title,
    this.svgSrc,
    this.icon,
    required this.press,
  }) : super(key: key);

  final String title;
  final String? svgSrc;
  final IconData? icon;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: press,
      horizontalTitleGap: 0.0,
      leading: svgSrc != null
          ? SvgPicture.asset(
        svgSrc!,
        colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
        height: 16,
      )
          : icon != null
          ? Icon(
        icon,
        color: Colors.white54,
        size: 16,
      )
          : SizedBox.shrink(), // Si no se proporciona ni svgSrc ni icon
      title: Text(
        title,
        style: TextStyle(color: Colors.white54),
      ),
    );
  }
}
