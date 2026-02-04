import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './features/auth';
import { FallAlertProvider, FallAlertOverlay } from './features/fall';
import { VideoCallProvider, VideoCallOverlay, IncomingCallOverlay } from './features/videocall';
import ProtectedRoute from './components/common/ProtectedRoute';
import FixedLayout from './components/common/FixedLayout';
import DisplayPage from './pages/DisplayPage';
import LoginPage from './pages/LoginPage';
import './App.css';

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <FallAlertProvider>
          <VideoCallProvider>
            <FallAlertOverlay />
            <VideoCallOverlay />
            <IncomingCallOverlay />
            <FixedLayout>
              <Routes>
                <Route path="/login" element={<LoginPage />} />
                <Route
                  path="/"
                  element={
                    <ProtectedRoute>
                      <DisplayPage />
                    </ProtectedRoute>
                  }
                />
                <Route path="*" element={<Navigate to="/" replace />} />
              </Routes>
            </FixedLayout>
          </VideoCallProvider>
        </FallAlertProvider>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
