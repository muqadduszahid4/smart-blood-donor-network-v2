\# 🩸 Smart Blood Donor Network



A Flutter app that connects blood donors with people in urgent need — in real time. It manages the full donation lifecycle: an emergency request is raised, a verified donor accepts it, and the donation is tracked through to completion.



Developed as part of the \*\*TEYZIX CORE Internship Program\*\*.



\---



\## 📱 How It Works



1\. \*\*Requester\*\* submits an emergency blood request (blood group, hospital, contact info) → status: `pending`

2\. \*\*Admin\*\* reviews and approves it → status: `active`, now visible to all donors

3\. \*\*Donor\*\* accepts the request → status: `accepted`, donor's contact info is shared with the requester

4\. \*\*Requester \& donor\*\* connect directly (call) and arrange the donation at the hospital

5\. \*\*Donor marks it complete\*\* → donation is logged, donor's eligibility countdown resets, requester sees "Completed"



Admin dashboard reflects live blood-group stats and request activity throughout.



\---



\## ✨ Key Features



\- 🔐 Firebase Authentication (sign up, login, password recovery)

\- 🆘 Emergency blood request system with admin approval

\- 🩸 Real-time donor response and matching (blood-type compatibility aware)

\- 📍 Nearby donors map (Flutter Map + Geolocator)

\- 🏥 Hospital \& blood bank directory — searchable by city, with Call \& WhatsApp contact

\- 🩺 Medical verification with trust badges

\- ⏳ Donation eligibility tracking (56-day rule) with admin-reviewed early-donation exceptions

\- 📊 Donation history

\- 🛠️ Admin panel for managing donors, requesters, hospitals, and requests

\- 🔔 Push notifications (Firebase Cloud Messaging)

\- 👤 Editable user profile



\---



\## 🛠️ Tech Stack



Flutter · Firebase (Auth, Firestore, Cloud Messaging) · Provider · flutter\_map · Geolocator · url\_launcher



\---



\## 📸 Screenshots



<p float="left">

&#x20; <img src="screenshots/Screenshot%202026-07-09%20115657.png" width="200" />

&#x20; <img src="screenshots/Screenshot%202026-07-09%20115750.png" width="200" />

&#x20; <img src="screenshots/Screenshot%202026-07-09%20115842.png" width="200" />

&#x20; <img src="screenshots/Screenshot%202026-07-09%20122721.png" width="200" />

&#x20; <img src="screenshots/Screenshot%202026-07-09%20122922.png" width="200" />

&#x20; <img src="screenshots/Screenshot%202026-07-09%20123052.png" width="200" />

&#x20; <img src="screenshots/Screenshot%202026-07-09%20123504.png" width="200" />

&#x20; <img src="screenshots/Screenshot%202026-07-09%20123527.png" width="200" />

&#x20; <img src="screenshots/Screenshot%202026-07-09%20123543.png" width="200" />

&#x20; <img src="screenshots/Screenshot%202026-07-09%20124247.png" width="200" />

&#x20; <img src="screenshots/Screenshot%202026-07-09%20124337.png" width="200" />

&#x20; <img src="screenshots/Screenshot%202026-07-09%20124354.png" width="200" />

&#x20; <img src="screenshots/Screenshot%202026-07-09%20124443.png" width="200" />

&#x20; <img src="screenshots/Screenshot%202026-07-09%20124933.png" width="200" />

&#x20; <img src="screenshots/Screenshot%202026-07-09%20125013.png" width="200" />

&#x20; <img src="screenshots/Screenshot%202026-07-09%20125047.png" width="200" />

&#x20; <img src="screenshots/Screenshot%202026-07-09%20125129.png" width="200" />

&#x20; <img src="screenshots/Screenshot%202026-07-09%20125143.png" width="200" />

</p>



\---



\## 📦 Download



📱 \*\*APK:\*\* \[Download app-release.apk (v1.1.0)](https://github.com/muqadduszahid4/smart-blood-donor-network-v2/releases/download/v1.1.0/app-release.apk)

🎥 \*\*Demo Video:\*\* Coming soon



\---



\## 🚀 Getting Started



```bash

git clone https://github.com/muqadduszahid4/smart-blood-donor-network-v2.git

cd smart-blood-donor-network-v2

flutter pub get

flutter run

```



> ⚠️ This project uses Firebase. To run it yourself, create a Firebase project and add your own `google-services.json` under `android/app/`.



\---



\## 🎓 Internship Acknowledgment



Developed as part of the \*\*TEYZIX CORE Internship Program\*\* — Mobile App Development track.

🌐 \[teyzixcore.com](https://www.teyzixcore.com)



\---



\## 👤 Author



\*\*Muqaddus Zahid\*\* — \[@muqadduszahid4](https://github.com/muqadduszahid4)

