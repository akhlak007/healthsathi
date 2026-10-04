import request from "supertest";
import {beforeEach, describe, expect, it, vi} from "vitest";
import {AuthService, createApp} from "./app";

function mockAuth(): AuthService {
  return {
    verifyIdToken: vi.fn().mockResolvedValue({admin: true}),
    getUser: vi.fn(),
    getUserByEmail: vi.fn(),
  };
}

describe("POST /api/admin/users/exists", () => {
  let auth: AuthService;

  beforeEach(() => {
    auth = mockAuth();
  });

  it("finds a user by normalized email", async () => {
    vi.mocked(auth.getUserByEmail).mockResolvedValue({uid: "user-1", disabled: false});

    const response = await request(createApp(auth))
      .post("/api/admin/users/exists")
      .set("Authorization", "Bearer admin-token")
      .send({email: "  Person@Example.COM "});

    expect(response.status).toBe(200);
    expect(response.body).toEqual({exists: true, uid: "user-1", disabled: false});
    expect(auth.getUserByEmail).toHaveBeenCalledWith("person@example.com");
  });

  it("finds a user by uid", async () => {
    vi.mocked(auth.getUser).mockResolvedValue({uid: "user-2", disabled: true});

    const response = await request(createApp(auth))
      .post("/api/admin/users/exists")
      .set("Authorization", "Bearer admin-token")
      .send({uid: " user-2 "});

    expect(response.status).toBe(200);
    expect(response.body).toEqual({exists: true, uid: "user-2", disabled: true});
    expect(auth.getUser).toHaveBeenCalledWith("user-2");
  });

  it("returns exists false for an unknown user", async () => {
    vi.mocked(auth.getUserByEmail).mockRejectedValue({code: "auth/user-not-found"});

    const response = await request(createApp(auth))
      .post("/api/admin/users/exists")
      .set("Authorization", "Bearer admin-token")
      .send({email: "missing@example.com"});

    expect(response.status).toBe(200);
    expect(response.body).toEqual({exists: false});
  });

  it.each([
    {},
    {email: "user@example.com", uid: "user-1"},
    {email: "not-an-email"},
    {uid: "  "},
    {email: "user@example.com", extra: true},
    {email: "user@example.com", uid: null},
    {uid: "user-1", email: false},
    {uid: "x".repeat(129)},
  ])("rejects invalid input: %j", async (body) => {
    const response = await request(createApp(auth))
      .post("/api/admin/users/exists")
      .set("Authorization", "Bearer admin-token")
      .send(body);

    expect(response.status).toBe(400);
  });

  it("rejects a request without a bearer token", async () => {
    const response = await request(createApp(auth))
      .post("/api/admin/users/exists")
      .send({uid: "user-1"});

    expect(response.status).toBe(401);
  });

  it("rejects an invalid bearer token", async () => {
    vi.mocked(auth.verifyIdToken).mockRejectedValue(new Error("invalid"));

    const response = await request(createApp(auth))
      .post("/api/admin/users/exists")
      .set("Authorization", "Bearer invalid-token")
      .send({uid: "user-1"});

    expect(response.status).toBe(401);
  });

  it("rejects a signed-in user without the admin claim", async () => {
    vi.mocked(auth.verifyIdToken).mockResolvedValue({admin: false});

    const response = await request(createApp(auth))
      .post("/api/admin/users/exists")
      .set("Authorization", "Bearer user-token")
      .send({uid: "user-1"});

    expect(response.status).toBe(403);
  });

  it("returns safe JSON for malformed JSON after authentication", async () => {
    const response = await request(createApp(auth))
      .post("/api/admin/users/exists")
      .set("Authorization", "Bearer admin-token")
      .set("Content-Type", "application/json")
      .send('{"uid":');

    expect(response.status).toBe(400);
    expect(response.body).toEqual({error: "Invalid JSON request body"});
  });

  it("returns safe JSON when the request body is too large", async () => {
    const response = await request(createApp(auth))
      .post("/api/admin/users/exists")
      .set("Authorization", "Bearer admin-token")
      .send({uid: "x".repeat(9000)});

    expect(response.status).toBe(413);
    expect(response.body).toEqual({error: "Request body is too large"});
  });

  it("authenticates before attempting to parse the JSON body", async () => {
    const response = await request(createApp(auth))
      .post("/api/admin/users/exists")
      .set("Content-Type", "application/json")
      .send('{"uid":');

    expect(response.status).toBe(401);
    expect(response.body).toEqual({error: "Authentication required"});
  });

  it("hides unexpected lookup errors", async () => {
    vi.mocked(auth.getUser).mockRejectedValue(new Error("secret internal details"));

    const response = await request(createApp(auth))
      .post("/api/admin/users/exists")
      .set("Authorization", "Bearer admin-token")
      .send({uid: "user-1"});

    expect(response.status).toBe(500);
    expect(response.body).toEqual({error: "Unable to check user existence"});
  });
});
