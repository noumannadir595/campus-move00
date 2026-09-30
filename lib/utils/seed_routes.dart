import 'package:firebase_database/firebase_database.dart';

import '../core/database.dart';

class SeedRoutes {
  /// ⚠️ EK BAAR RUN KARO — Purane routes delete karke naye 20 add karega
  /// Run ke baad main.dart se line hata do
  static Future<void> clearAndSeed() async {
    print('🗑️ Deleting old routes...');
    await getDatabase().ref('routes').remove();

    print('📥 Adding 20 new routes...');

    final List<Map<String, dynamic>> routes = [
      // ==================== ROUTE 1 ====================
      {
        'routeNumber': '1',
        'name': 'Route 1: CUI - Depalpurr',
        'stops':
            'Haveli Lakha Chowk, Rizvi Chowk, Civil Hospital Depalpurr, Bus Stand Depalpurr, 32/2-L, City Court Chowk Depalpurr, 49/2-L, 51/2-L, Okara By Pass, 50/2-L, 52/2-L, City Court Bypass Okara, Adda Tabrook, AL-Brak Check Post, Al-Jehad Check Post, Runway, Adda Gamber H.B.L, 55/5-L, Qadra Baad, Yousaf Wala, CUI Sahiwal',
        'timing': '6:30 AM - 8:20 AM',
        'driverName': 'Ghulam Mustafa',
        'driverPhone': '0300-6961554',
        'conductorName': 'Irfan Ali',
        'conductorPhone': '0305-2135757',
        'busNumber': 'SLJ-45',
        'startPoint': 'CUI',
        'endPoint': 'Depalpurr',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },

      // ==================== ROUTE 2 ====================
      {
        'routeNumber': '2',
        'name': 'Route 2: CUI - Okara',
        'stops':
            'Total Pump, Crown Society, Crown PSO Pump, Sardar Chowk, Green City, 1.Chak Pathak, Govt Colony, Ali Raza Hotel, Sikandar Chowk, Venus Chowk, Mehar Petrolium, Ashraf Sohna Pump, Nehar Wala Pull, CUI Sahiwal',
        'timing': '6:30 AM - 8:15 AM',
        'driverName': 'Syed Nadeem Abbas',
        'driverPhone': '0305-6501536',
        'conductorName': 'Waheed Ahmad',
        'conductorPhone': '0307-4991483',
        'busNumber': 'SL-027',
        'startPoint': 'CUI',
        'endPoint': 'Okara',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },

      // ==================== ROUTE 3 ====================
      {
        'routeNumber': '3',
        'name': 'Route 3: CUI - Okara',
        'stops':
            'Total Pump, Mia Cash Carry, King Ways, Anwar Shopping Mall, Ravi Book Depo, Mehboob Alam Chowk, Harni Wala Chowk, Sonehri Bank, Dehli Sweet, Ahmad Cash & Carry, CUI Sahiwal',
        'timing': '6:30 AM - 8:15 AM',
        'driverName': 'Mujahid Ali',
        'driverPhone': '0304-6952275',
        'conductorName': 'Muhamad Rizwan',
        'conductorPhone': '0302-4898480',
        'busNumber': 'SLI-43',
        'startPoint': 'CUI',
        'endPoint': 'Okara',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },

      // ==================== ROUTE 4 ====================
      {
        'routeNumber': '4',
        'name': 'Route 4: CUI - Renala Khurd',
        'stops':
            'PSO Pump, 11 Chak Pathak, Manzor Hospital, Nadra Office, Kalma Chowk, Girls College, Shaukat abbad Mor, Sahara City, Kissan Adda, Jawad Avenue, Allied Pump, Larid Adda, Chungi No. 07, CUI Sahiwal',
        'timing': '6:20 AM - 8:15 AM',
        'driverName': 'Muhammad Iqbal',
        'driverPhone': '0301-7861386',
        'conductorName': 'Abbad Ali',
        'conductorPhone': '0307-6029129',
        'busNumber': 'SLJ-47',
        'startPoint': 'CUI',
        'endPoint': 'Renala Khurd',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },

      // ==================== ROUTE 5 ====================
      {
        'routeNumber': '5',
        'name': 'Route 5: CUI - Okara',
        'stops':
            'Total Pump By Pass, South City Hospital, Rana Basit Factory, Mai Wali Masjid, Nadeem Honda, Punjab Bank, Depalpurr Chowk, Daewoo Adda, Chung No. 06, Makka CNG, Garden Town, Satluj School, Cotton Factory, CUI Sahiwal',
        'timing': '6:30 AM - 8:15 AM',
        'driverName': 'Fayyaz Mehmood',
        'driverPhone': '0301-4192946',
        'conductorName': 'Sajid Mehmood',
        'conductorPhone': '0305-1629656',
        'busNumber': 'SLJ-1024',
        'startPoint': 'CUI',
        'endPoint': 'Okara',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },

      // ==================== ROUTE 6 ====================
      {
        'routeNumber': '6',
        'name': 'Route 6: CUI - Okara',
        'stops':
            'Total Pump By Pass, Attock Petrol Pump, Zaiqa Sweets, Khan Colony - 1, Bismillah Petrol Pump, Rehmat-ullah Town, Dehli Sweets, Ghalla Mandi, Canal Bridge, CUI Sahiwal',
        'timing': '6:30 AM - 8:20 AM',
        'driverName': 'Abdul Khaliq',
        'driverPhone': '0325-9962711',
        'conductorName': 'Muhammad Afzal',
        'conductorPhone': '0321-6966304',
        'busNumber': 'SLG-1053',
        'startPoint': 'CUI',
        'endPoint': 'Okara',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },

      // ==================== ROUTE 7 ====================
      {
        'routeNumber': '7',
        'name': 'Route 7: CUI - ChichaWattni',
        'stops':
            'Ghazi Abbad, 22/9-L, 11/9-L, 15/9-L, 14/9-L, Sai Di Khoi, 41/11-L, Housing Colony Chichawattni, Ayesha Clinic, Makka Masjid Chowk, Bismillah Chowk, Waqas Sweet, Degree College, Tower Stop, Shopo City, Harrapa Station, 87/9-L, 38/9-L, 32/9-L, CUI Sahiwal Campus',
        'timing': '6:30 AM - 8:20 AM',
        'driverName': 'Muhammad Ramzan',
        'driverPhone': '0302-4227430',
        'conductorName': 'Asghar Ali',
        'conductorPhone': '0303-2237351',
        'busNumber': 'SLJ-026',
        'startPoint': 'CUI',
        'endPoint': 'ChichaWattni',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },

      // ==================== ROUTE 8 ====================
      {
        'routeNumber': '8',
        'name': 'Route 8: CUI - ChichaWattni',
        'stops':
            'Ray Hospital, Lakar Mandi, City Pull, Lari Adda Chichawattni, Larid Adda Pathak, Chishti Chowk, 11 Morr, Chak 10 Old Harrapa Road, Chandni Chowk, Chak No. 06 Old Harrapa Road, Lodhi Petrol Pump, Go Pump, Joyia Wala Morr, Adda Jhall, Adda Booti Paal, 97/6-R, Law Colony, PSO Pump, Daray Wala Khokha, Anmol Marriage Hall, Bilaly Masjid, Arifwala Wala Pull, Baba Farid Park, Chungi 90, CUI Sahiwal Campus',
        'timing': '7:00 AM - 8:20 AM',
        'driverName': 'Ijaz Ahmad',
        'driverPhone': '0322-6918035',
        'conductorName': 'Zaheer Abbas',
        'conductorPhone': '0305-5445211',
        'busNumber': 'SLG-1026',
        'startPoint': 'CUI',
        'endPoint': 'ChichaWattni',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },

      // ==================== ROUTE 9 ====================
      {
        'routeNumber': '9',
        'name': 'Route 9: CUI - Kasowal',
        'stops':
            'Bus Parking Kasowall, Kotla, 11/12-L, 10/12-L, Taaj Petrol Pump, Rescue 1122, Nadra Office, Huma Bashir Hospital, Taaj Markee, Raja Petrol Pump, Bismillah Petrol Pump, AL-Ghanni Petroleum, 39 Chowk By Pass, Shell Pump, Dad Fatiyana, Chak 7/11-L, Chak 6/11-L, Chak 5/11-L, Chak 3/10-L, Nai Wala Bypass, 134/9-L Bypass, CUI Sahiwal Campus',
        'timing': '6:30 AM - 8:15 AM',
        'driverName': 'Sadat Mand',
        'driverPhone': '0301-6379625',
        'conductorName': 'Ali Ejaz',
        'conductorPhone': '0307-4991483',
        'busNumber': 'SLJ-025',
        'startPoint': 'CUI',
        'endPoint': 'Kasowal',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },

      // ==================== ROUTE 10 ====================
      {
        'routeNumber': '10',
        'name': 'Route 10: CUI - Gago Mandi',
        'stops':
            'Gago Mandi, 25/85, 17/E.B, Adda Quarter, Adda Rasol Purr, 167/E.B, 65 Shahzaday Wala, Adda Fitna, Bahar Wala Adda, Pakistan GO Pump, Tarikhnee Mor, Chak 149/E.B, Chak-134/EB, Chak 38/E.B, Adda Kameer Shareef, Chak 26/E.B, Khawaja Arif, Shabil Adda, Hi - Tack, Pasha Hotel, Ajwa City, CUI Sahiwal',
        'timing': '6:20 AM - 8:15 AM',
        'driverName': 'Farrukh Bashir',
        'driverPhone': '0300-2955498',
        'conductorName': 'Rao Waqas Ali',
        'conductorPhone': '0301-3788008',
        'busNumber': 'SAM-712',
        'startPoint': 'CUI',
        'endPoint': 'Gago Mandi',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },

      // ==================== ROUTE 11 ====================
      {
        'routeNumber': '11',
        'name': 'Route 11: CUI - Qaboola',
        'stops':
            'Go Pump, Agriculture University, Rest House, Faisal Town, Kumharan Walla Chowk, Pathak, Fatima Jinnah Park, LRBT Hospital, Wahab Colony, Mota Colony, College Chowk, TMA Chowk, Gol Chaker, Shafi Shadi Chowk, Ansari Chowk, Car Stand, Police Station, CUI Sahiwal',
        'timing': '6:15 AM - 8:20 AM',
        'driverName': 'Haji Arshad Ali',
        'driverPhone': '0304-8821115',
        'conductorName': 'Waqas Mehmood',
        'conductorPhone': '0301-1374346',
        'busNumber': 'SLI-1025',
        'startPoint': 'CUI',
        'endPoint': 'Qaboola',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },

      // ==================== ROUTE 12 ====================
      {
        'routeNumber': '12',
        'name': 'Route 12: CUI - Pakpattan',
        'stops':
            'Jamal Chowk Factory, Bijli Chowk, Juma Bazar Chowk, Gulshan Fareed Colony, Tehsil Office, Freed Nagar Chowk, Freed Nagar Rice Mill, Thana Farid Nagar, City Courts, Oxford College, AL- Fareed Garden (PSO), Green Town, 19.SP Pull, Jamal Chowk, Bahi wall Pull, Malka Haance, Noor Jhang, Noor Purr HBL, Noor Purr ABL, Shugar Mill, Petroling Check Post, 8th Meel Stop, CUI Sahiwal',
        'timing': '6:30 AM - 8:20 AM',
        'driverName': 'Muhammad Adnan Bashir',
        'driverPhone': '0304-4837957',
        'conductorName': 'Muhammad Tayyab',
        'conductorPhone': '0307-7787791',
        'busNumber': 'SLJ-46',
        'startPoint': 'CUI',
        'endPoint': 'Pakpattan',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },

      // ==================== ROUTE 13 ====================
      {
        'routeNumber': '13',
        'name': 'Route 13: CUI - Pakpattan',
        'stops':
            'Jamal Chowk Factory, Madina Town, Kameer Chungi Masjid Stop, Petrol Pump Stop, Malak Purr Rajbah Pull, Bypass Hota Road, Halaal Book Depo, Nagina Chowk, Thana City, Konica Lab, Lari Adda (Old Phatak), PSO Pump, 1122 Office Stop, Factory Pull, CUI Sahiwal',
        'timing': '6:30 AM - 8:20 AM',
        'driverName': 'Shahid Imran',
        'driverPhone': '0307-4839078',
        'conductorName': 'Rao M. Ayoub',
        'conductorPhone': '0303-4219186',
        'busNumber': 'SLJ-41',
        'startPoint': 'CUI',
        'endPoint': 'Pakpattan',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },

      // ==================== ROUTE 14 ====================
      {
        'routeNumber': '14',
        'name': 'Route 14: CUI - Sahiwal',
        'stops':
            'CUI Sahiwal, Old Sui Gas Office, Daigh Wali Kothi, Stop No. 03, Daigh Wala Chowk, Tasty Pizza, Beauty Parlor, A-Mart, Medical College Chowk, Jump Wala Chowk, Dubai Chowk, Population Welfare, Anti Corruption Office, Education Office, College Chowk, Ghora Chowk, Jahaz Chowk, HBL, Attock Pump, Peer Bukhari, CUI Sahiwal',
        'timing': '6:30 AM - 8:10 AM',
        'driverName': 'Abid Ali',
        'driverPhone': '0300-7839994',
        'conductorName': 'Sajid Latif',
        'conductorPhone': '0303-7995005',
        'busNumber': 'SLJ-44',
        'startPoint': 'CUI',
        'endPoint': 'Sahiwal',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },

      // ==================== ROUTE 15 ====================
      {
        'routeNumber': '15',
        'name': 'Route 15: CUI - Sahiwal',
        'stops':
            'CUI Sahiwal, 88 Neky Wala, Darbar, Rafi Garden Gate - 1, Rafi Garden Main Gate, G-1 City, MCB Bank, Nor Bakery, Shadman Chowk, Go Pump, Girls Hostel, CUI Sahiwal',
        'timing': '6:30 AM - 8:20 AM',
        'driverName': 'M. Iqbal Gill',
        'driverPhone': '0300-6907685',
        'conductorName': 'Rana Sajid',
        'conductorPhone': '0305-8287941',
        'busNumber': 'SAK-035',
        'startPoint': 'CUI',
        'endPoint': 'Sahiwal',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },

      // ==================== ROUTE 16 ====================
      {
        'routeNumber': '16',
        'name': 'Route 16: CUI - Sahiwal',
        'stops':
            'CUI Sahiwal, Girls Hostel, HBL Bank, Attok Pump, Peer Bukhari, CUI Sahiwal',
        'timing': '8:30 AM - 9:45 AM',
        'driverName': 'Naveed Ahmad',
        'driverPhone': '0300-8535462',
        'conductorName': '',
        'conductorPhone': '',
        'busNumber': 'SLG-42',
        'startPoint': 'CUI',
        'endPoint': 'Sahiwal',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },

      // ==================== ROUTE 17 ====================
      {
        'routeNumber': '17',
        'name': 'Route 17: CUI - Sahiwal',
        'stops':
            'CUI Sahiwal, Bilaly Masjid, Officer Colony, Daray Wala Khokha, PSO Pump, Law Colony, Jahaz Ground, Girls Hostel, CUI Sahiwal',
        'timing': '6:00 AM - 7:45 AM',
        'driverName': 'Adnan Bashir',
        'driverPhone': '0306-1590699',
        'conductorName': 'Sajid Latif',
        'conductorPhone': '0303-7995005',
        'busNumber': 'SLI-42',
        'startPoint': 'CUI',
        'endPoint': 'Sahiwal',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },

      // ==================== ROUTE 18 ====================
      {
        'routeNumber': '18',
        'name': 'Route 18: CUI - Sahiwal',
        'stops':
            'CUI Sahiwal, 86-Chowk, Shadman Chowk, Gate No. 04 Civil Hospital Gate, Nawaz Sharif Park, Mall Mandi Chowk, Excise Office, The Educator School, City Mart, Kashti Chowk, Nizami Masjid Chowk, Madina Chowk, Faridia Park Gate, Bilal Colony, Bhutta Petrol Pump, Mazdor Pulli, Dawood Chowk, Tana Bana, Lasani, Decent Bakery, Tanki Chowk, Joggi Chowk, Creascent CNG, Pakpattan Chowk, Johar Town, CUI Sahiwal',
        'timing': '6:30 AM - 8:10 AM',
        'driverName': 'Sana Ullah',
        'driverPhone': '0305-7376120',
        'conductorName': '',
        'conductorPhone': '',
        'busNumber': 'SLG 1056',
        'startPoint': 'CUI',
        'endPoint': 'Sahiwal',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },

      // ==================== SHUTTLE 1 ====================
      {
        'routeNumber': '19',
        'name': 'Shuttle 1: CUI - Sahiwal City',
        'stops':
            'CUI Sahiwal, Bhutta Pump, Faridia Park, Girls College Chowk, Bin Shafiq, Mission Chowk, Mall Mandi Chowk, Civil Hospital, Go Pump, Anti Corruption, Ganj Shakar Chowk, Speed Braker, A-Mart, Tasty Pizza, Daig Wala Chowk, Daig Wala Kothi, College Chowk, CUI Sahiwal',
        'timing': '8:30 AM - 9:50 AM',
        'driverName': 'Naveed Ahmad',
        'driverPhone': '0300-8535462',
        'conductorName': '',
        'conductorPhone': '',
        'busNumber': 'SLG-42',
        'startPoint': 'CUI',
        'endPoint': 'Sahiwal City',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },

      // ==================== SHUTTLE 2 ====================
      {
        'routeNumber': '20',
        'name': 'Shuttle 2: CUI - Sahiwal City',
        'stops':
            'CUI Sahiwal, Girls Hostel, HBL Bank, Attok Pump, Peer Bukhari, CUI Sahiwal',
        'timing': '8:30 AM - 9:45 AM',
        'driverName': 'M. Iqbal Gill',
        'driverPhone': '0300-6907685',
        'conductorName': 'Rana Sajid',
        'conductorPhone': '0305-8287941',
        'busNumber': 'SAK-035',
        'startPoint': 'CUI',
        'endPoint': 'Sahiwal City',
        'startLat': null,
        'startLng': null,
        'endLat': null,
        'endLng': null,
      },
    ];

    for (var route in routes) {
      await getDatabase().ref('routes').push().set({
        ...route,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });
      print('✅ Added: ${route['name']}');
    }

    print('🎉 All 20 routes added successfully!');
  }
}