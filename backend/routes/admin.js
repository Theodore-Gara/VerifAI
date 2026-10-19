const express = require('express');
const { requireAdminAuth } = require('../middleware/admin');
const { requireRole } = require('../middleware/adminRoles');
const {
  getOverview, listTasks, createTask, deleteTask,
  listUsers, getUser, setUserStatus, listModeration, trackProgress,
  getTaskDetail, updateTask, importTasks, getTaskAnswers, listApprovals, reviewTask,
  answerSummary, listAnswers, getAnalytics,
  listLab, getLabLesson, updateLabSection,
  listWorkshopPosts, listWorkshopReports, moderateWorkshopPost,
  grantAdjust, exportUserData, hardDeleteUser, setFirebaseDisabled,
  getSystem, getConfigValues, updateConfigValues, listAdmins, addAdmin, removeAdmin,
  exportUsersCsv, exportAttemptsCsv, exportTracksCsv,
} = require('../controllers/adminController');

const router = express.Router();

// Every admin route requires a verified Firebase token AND admin status
// (an `admin: true` custom claim or an email in ADMIN_EMAILS). Role then
// decides which of these endpoints the caller may use:
//   moderator  — read-mostly: overview, lists, workshop, audit log
//   admin      — content + user management (the default allowlist role)
//   super      — also config, admin registry and destructive GDPR actions
router.use(requireAdminAuth);
router.use(requireRole('moderator'));

// Overview + analytics
router.get('/overview', getOverview);
router.get('/track-progress', trackProgress);
router.get('/system', getSystem);

// Tasks: read for all admins; write for admin and above.
router.get('/tasks', listTasks);
router.get('/tasks/:id(\\d+)', getTaskDetail);
router.get('/tasks/:id(\\d+)/answers', getTaskAnswers);
router.post('/tasks', requireRole('admin'), createTask);
router.put('/tasks/:id(\\d+)', requireRole('admin'), updateTask);
router.post('/tasks/import', requireRole('admin'), importTasks);
router.post('/tasks/:id(\\d+)/approval', requireRole('moderator'), reviewTask);
router.delete('/tasks/:id(\\d+)', requireRole('admin'), deleteTask);

// Approval queue (viewing for all admins, decisions are moderator+)
router.get('/approvals', listApprovals);

// Per-department answer tracking
router.get('/answers/summary', answerSummary);
router.get('/answers', listAnswers);

// App-wide analytics
router.get('/analytics', getAnalytics);

// Lab / textbook content
router.get('/lab', listLab);
router.get('/lab/:id(\\d+)', getLabLesson);
router.put('/lab/sections/:id(\\d+)', requireRole('admin'), updateLabSection);

// Workshop moderation
router.get('/workshop', listWorkshopPosts);
router.get('/workshop/reports', listWorkshopReports);
router.post('/workshop/:id(\\d+)', requireRole('moderator'), moderateWorkshopPost);

// Users
router.get('/users', listUsers);
router.get('/users/:id(\\d+)', getUser);
router.post('/users/:id/status', requireRole('moderator'), setUserStatus);
router.post('/users/:id/grant', requireRole('admin'), grantAdjust);
router.get('/users/:id/export', requireRole('admin'), exportUserData);
router.post('/users/:id/firebase', requireRole('admin'), setFirebaseDisabled);
router.delete('/users/:id(\\d+)', requireRole('super'), hardDeleteUser);

// Audit log
router.get('/moderation', listModeration);

// Exports (PII — admin and above)
router.get('/export/users.csv', requireRole('admin'), exportUsersCsv);
router.get('/export/attempts.csv', requireRole('admin'), exportAttemptsCsv);
router.get('/export/tracks.csv', requireRole('admin'), exportTracksCsv);

// System config + admin registry
router.get('/config', getConfigValues);
router.put('/config', requireRole('admin'), updateConfigValues);
router.get('/admins', requireRole('super'), listAdmins);
router.post('/admins', requireRole('super'), addAdmin);
router.delete('/admins/:email', requireRole('super'), removeAdmin);

module.exports = router;
