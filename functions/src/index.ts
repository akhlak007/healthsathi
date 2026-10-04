import {getApps, initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {onRequest} from "firebase-functions/v2/https";
import {createApp} from "./app";

if (getApps().length === 0) {
  initializeApp();
}

const app = createApp(getAuth());

export const adminApi = onRequest(
  {
    region: "asia-south1",
    timeoutSeconds: 30,
  },
  app,
);
