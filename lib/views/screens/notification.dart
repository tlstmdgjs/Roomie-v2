import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_app_ui/util/user.dart';
import 'other_profile.dart';
import 'package:social_app_ui/util/api.dart';

class Noti extends StatefulWidget {
  final String email;
  Noti({Key? key, required this.email}) : super(key: key);

  @override
  State<Noti> createState() => _NotiState();
}

class _NotiState extends State<Noti> {
  Map<String, bool> acceptanceStatus = {};
  Map<String, bool> rejectionStatus = {};

  Stream<QuerySnapshot> getMatchingRequestsStream(String receiverEmail) {
    CollectionReference matchingColRef =
        FirebaseFirestore.instance.collection('matching');
    return matchingColRef
        .where('receiverEmail', isEqualTo: receiverEmail)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<RoomieUser> getUserFromFirestore(String otheruser) async {
    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(otheruser)
          .get();
      if (docSnapshot.exists) {
        Map<String, dynamic> userData =
            docSnapshot.data() as Map<String, dynamic>;
        Map<String, dynamic> essentials =
            userData['essentials'] ?? RoomieUser.essentialInitialize();
        Map<String, dynamic> survey =
            userData['survey'] ?? RoomieUser.answerInitialize();
        String pushToken = userData['pushToken'] ?? '';

        return RoomieUser(
          email: otheruser,
          essentials: essentials,
          survey: survey,
          pushToken: pushToken,
        );
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return RoomieUser.init(otheruser);
  }

  Future<void> updateConnectedField(
      String otherUserEmail, int connectedValue) async {
    try {
      DocumentReference otherUserDocRef =
          FirebaseFirestore.instance.collection('users').doc(otherUserEmail);

      Map<String, dynamic> updateData = {'connected': connectedValue};

      await FirebaseFirestore.instance.runTransaction((Transaction) async {
        await Transaction.update(otherUserDocRef, updateData);
      });

      print('상대방의 connected 필드가 업데이트되었습니다. 값: $connectedValue');

      if (connectedValue == 1) {
        DocumentReference myDocRef =
            FirebaseFirestore.instance.collection('users').doc(widget.email);

        await FirebaseFirestore.instance.runTransaction((Transaction) async {
          await Transaction.update(myDocRef, updateData);
        });

        print('내 connected 필드도 업데이트되었습니다. 값: $connectedValue');
      }
    } catch (e) {
      print('connected 필드 업데이트 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('알림'),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: getMatchingRequestsStream(widget.email),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text('오류발생: ${snapshot.error}'),
              );
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text('신청내역이 없습니다.'),
              );
            } else {
              List<QueryDocumentSnapshot> matchingRequests =
                  snapshot.data!.docs;
              return ListView.builder(
                  itemCount: matchingRequests.length,
                  itemBuilder: (context, index) {
                    QueryDocumentSnapshot requestSnapshot =
                        matchingRequests[index];
                    String senderEmail =
                        requestSnapshot['senderEmail'] as String;
                    Timestamp timestamp =
                        requestSnapshot['timestamp'] as Timestamp;
                    DateTime dateTime = timestamp.toDate();
                    String formattedTime =
                        "${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}";
                    return GestureDetector(
                      onTap: () async {
                        RoomieUser senderUser =
                            await getUserFromFirestore(senderEmail);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtherProfile(
                              user: senderUser,
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        title: Text(
                          '$senderEmail님이 룸메이트 신청을 요청했습니다.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              '$formattedTime',
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                RoomieUser senderUser =
                                    await getUserFromFirestore(senderEmail);
                                updateConnectedField(senderEmail, 1);
                                final pushToken = senderUser.pushToken;

                                await APIs.sendMatchNotification(
                                  pushToken ?? 'defaultPushToken',
                                  '룸메이트 신청이 수락 되었습니다.',
                                );

                                setState(() {
                                  acceptanceStatus[senderEmail] = true;
                                  rejectionStatus[senderEmail] = false;
                                });
                              },
                              child: Text(acceptanceStatus[senderEmail] == true
                                  ? '매칭됨'
                                  : '수락'),
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor:
                                      acceptanceStatus[senderEmail] == true
                                          ? Colors.green[600]
                                          : Colors.blue[600],
                                  textStyle:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                RoomieUser senderUser =
                                    await getUserFromFirestore(senderEmail);
                                updateConnectedField(senderEmail, 0);
                                final pushToken = senderUser.pushToken;

                                if (acceptanceStatus[senderEmail] != true) {
                                  await APIs.sendMatchNotification(
                                    pushToken ?? 'defaultPushToken',
                                    '룸메이트 신청이 거절 되었습니다.',
                                  );
                                } else {
                                  await APIs.sendCancelNotification(
                                      pushToken ?? 'defaultPushToken',
                                      '룸메이트 취소가 요청되었습니다.');
                                }
                                await FirebaseFirestore.instance
                                    .collection('matching')
                                    .doc(requestSnapshot.id)
                                    .delete();

                                setState(() {
                                  acceptanceStatus[senderEmail] = false;
                                  rejectionStatus[senderEmail] = true;

                                  matchingRequests.removeAt(index);
                                });
                              },
                              child: Text(acceptanceStatus[senderEmail] == true
                                  ? '취소'
                                  : '거절'),
                              style: ElevatedButton.styleFrom(
                                  foregroundColor:
                                      acceptanceStatus[senderEmail] == true
                                          ? Colors.white
                                          : Colors.black,
                                  backgroundColor:
                                      acceptanceStatus[senderEmail] == true
                                          ? Colors.red[700]
                                          : Colors.grey[300],
                                  textStyle:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
            }
          },
        ));
  }
}
