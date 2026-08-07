# Deploying LLM-Climate-Health so it's reachable online at any time

The repo is already deploy-ready: `Dockerfile` builds the Flutter web
frontend and the FastAPI backend into a single container that serves both
from one URL. What's left requires *your* accounts (GitHub, a hosting
provider) since those can't be created on your behalf.

## 1. Push the code to GitHub

```
cd LLM-Climate-Health
git add -A
git commit -m "Initial version of the climate-health ETL platform"
```

Create a new repository on github.com (can be private), then:

```
git remote add origin https://github.com/<your-username>/<repo-name>.git
git branch -M main
git push -u origin main
```

## 2. Deploy on Render.com (free tier)

1. Sign up at https://render.com (GitHub login is fastest).
2. **New +** → **Web Service** → connect the GitHub repo you just pushed.
3. Render will detect the `Dockerfile` automatically. Set:
   - **Environment**: Docker
   - **Instance type**: Free
4. Add an environment variable (Render dashboard → Environment):
   - `GEMINI_API_KEY` = your Gemini key (the same one in `backend/.env` —
     never commit that file, it's already in `.gitignore`)
5. Click **Create Web Service**. First build takes ~5-10 minutes (it builds
   Flutter web from source).
6. Render gives you a permanent URL like `https://your-app.onrender.com`.
   Share that with your professor — it serves both the UI and the API.

**Free-tier note**: the service sleeps after ~15 minutes of inactivity and
takes ~30-50 seconds to wake up on the next request. Fine for a professor
checking in occasionally; not for a low-latency production demo.

## 3. Local demo (what's running right now)

For tomorrow's live demo, no deployment is required — everything already
runs locally:

```
# Terminal 1 — backend
cd backend
uvicorn app.main:app --port 8000

# Terminal 2 — frontend (opens Chrome automatically)
cd frontend
flutter run -d chrome --web-port=5173
```
