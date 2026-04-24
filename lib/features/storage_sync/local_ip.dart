// Не осилил, пока прошу юзера отключить VPN. В будущем видимо придется сканировать сеть

// import 'dart:convert';
// import 'dart:io';

// import 'package:coldcall/core/err.dart';
// import 'package:coldcall/core/log.dart';

// Future<String?> getMyLocalIp() async {
//   bool isPrivateIP(String ip) {
//     final parts = ip.split('.').map(int.tryParse).toList();
//     if (parts.length != 4 || parts.any((p) => p == null)) return false;

//     // 192.168.x.x
//     if (parts[0] == 192 && parts[1] == 168) return true;
//     // 10.x.x.x
//     if (parts[0] == 10) return true;
//     // 172.16.x.x - 172.31.x.x
//     if (parts[0] == 172 && (parts[1]! >= 16 && parts[1]! <= 31)) return true;

//     return false;
//   }

// final vpnNames = ['tun', 'ppp', 'tap', 'wg']

//   try {
//     final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLinkLocal: false);
//     for (final interface in interfaces) {
//       for (final address in interface.addresses) {
//         Log.deb(jsonEncode(address));
//         final name = interface.name.toLowerCase();
//         final addr = address.address;

//         // Игнорируем VPN-интерфейсы по именам
//         if (name.contains('tun') || name.contains('ppp')) continue;

//         if (address.isLoopback) continue;

//         if (name.contains('wlan')) {
//           return addr; // Это 100% локальный Wi-Fi (даже если он в диапазоне 10.х)
//         }

//         // if (isPrivateIP(addr)) {
//         //   return addr;
//         // }
//       }
//     }
//   } catch (e, s) {
//     Err.add(e, s);
//   }
//   return null;
// }
