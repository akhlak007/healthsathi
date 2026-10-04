import cors from "cors";
import express, {NextFunction, Request, Response} from "express";

export interface AuthUser {
  uid: string;
  disabled: boolean;
}

export interface AuthService {
  verifyIdToken(token: string): Promise<unknown>;
  getUser(uid: string): Promise<AuthUser>;
  getUserByEmail(email: string): Promise<AuthUser>;
}

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function errorStringProperty(error: unknown, property: string): string | undefined {
  if (typeof error !== "object" || error === null || !(property in error)) {
    return undefined;
  }

  const value = (error as Record<string, unknown>)[property];
  return typeof value === "string" ? value : undefined;
}

function requireAdmin(auth: AuthService) {
  return async (req: Request, res: Response, next: NextFunction) => {
    const authorization = req.header("authorization");
    const match = authorization?.match(/^Bearer\s+(.+)$/i);

    if (!match) {
      res.status(401).json({error: "Authentication required"});
      return;
    }

    try {
      const decodedToken = await auth.verifyIdToken(match[1]);
      if (typeof decodedToken !== "object" || decodedToken === null ||
          !("admin" in decodedToken) || decodedToken.admin !== true) {
        res.status(403).json({error: "Admin access required"});
        return;
      }

      next();
    } catch {
      res.status(401).json({error: "Invalid authentication token"});
    }
  };
}

export function createApp(auth: AuthService) {
  const app = express();

  app.disable("x-powered-by");
  app.use(cors({
    origin: true,
    methods: ["POST", "OPTIONS"],
    allowedHeaders: ["Authorization", "Content-Type"],
  }));

  app.post(
    "/api/admin/users/exists",
    requireAdmin(auth),
    express.json({limit: "8kb"}),
    async (req: Request, res: Response) => {
      if (!req.is("application/json")) {
        res.status(400).json({error: "A JSON request body is required"});
        return;
      }

      const body = req.body;
      if (typeof body !== "object" || body === null || Array.isArray(body)) {
        res.status(400).json({error: "Provide exactly one of email or uid"});
        return;
      }

      const keys = Object.keys(body);
      if (keys.length !== 1 || (keys[0] !== "email" && keys[0] !== "uid")) {
        res.status(400).json({error: "Provide exactly one of email or uid"});
        return;
      }

      const identifier = body[keys[0]];
      if (typeof identifier !== "string") {
        res.status(400).json({error: "Provide a valid email or uid"});
        return;
      }

      const email = keys[0] === "email" ? identifier.trim().toLowerCase() : undefined;
      const uid = keys[0] === "uid" ? identifier.trim() : undefined;

      if ((email !== undefined && !emailPattern.test(email)) ||
          (uid !== undefined && (uid.length === 0 || uid.length > 128))) {
        res.status(400).json({error: "Provide a valid email or uid"});
        return;
      }

      try {
        const user = email !== undefined ?
          await auth.getUserByEmail(email) :
          await auth.getUser(uid!);

        res.status(200).json({
          exists: true,
          uid: user.uid,
          disabled: user.disabled,
        });
      } catch (error) {
        if (errorStringProperty(error, "code") === "auth/user-not-found") {
          res.status(200).json({exists: false});
          return;
        }

        res.status(500).json({error: "Unable to check user existence"});
      }
    },
  );

  app.use((_req, res) => {
    res.status(404).json({error: "Not found"});
  });

  app.use((
    error: unknown,
    _req: Request,
    res: Response,
    _next: NextFunction,
  ) => {
    const type = errorStringProperty(error, "type");
    const status = typeof error === "object" && error !== null && "status" in error ?
      error.status : undefined;

    if (type === "entity.parse.failed") {
      res.status(400).json({error: "Invalid JSON request body"});
      return;
    }

    if (type === "entity.too.large" || status === 413) {
      res.status(413).json({error: "Request body is too large"});
      return;
    }

    res.status(500).json({error: "Internal server error"});
  });

  return app;
}
