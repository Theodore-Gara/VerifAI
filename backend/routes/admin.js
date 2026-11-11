const express = require('express');
const { requireAdminAuth } = require('../middleware/admin');
const { requireRole } = require('../middleware/adminRoles');
const {
  getOverview, listTasks, createTask, deleteTask,
  listUsers, getUser, setUserStatus, updateUser, listModeration, trackProgress,
  getTaskDetail, updateTask, importTasks, getTaskAnswers, listApprovals, reviewTask,
  answerSummary, listAnswers, getAnalytics,
  listLab, getLabLesson, updateLabSection,
  listWorkshopPosts, listWorkshopReports, moderateWorkshopPost,
  grantAdjust, exportUserData, hardDeleteUser, setFirebaseDisabled,
  getSystem, getConfigValues, updateConfigValues, listAdmins, addAdmin, removeAdmin,
  exportUsersCsv, exportAttemptsCsv, exportTracksCsv,
  recordAdminSession,
} = require('../controllers/adminController');

const {
  listHelp, updateHelp, listFaqs, updateFaq, listMessages, updateMessage,
  getMessage, replyToMessage, markMessageRead, getUnreadCount, getInsights,
} = require('../controllers/adminSupportController');

const router = express.Router();

// Every admin route requires a verified Firebase token AND admin status
// (an `admin: true` custom claim or an email in ADMIN_EMAILS). Role then
// decides which of these endpoints the caller may use:
//   moderator  – read-mostly: overview, lists, workshop, audit log
//   admin      – content + user management (the default allowlist role)
//   super      – also config, admin registry and destructive GDPR actions
router.use(requireAdminAuth);
router.use(requireRole('moderator'));

// Overview + analytics
router.get('/overview', getOverview);
router.get('/track-progress', trackProgress);
router.get('/system', getSystem);

// Records an admin portal sign-in in the audit trail.
router.post('/session', recordAdminSession);

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
router.patch('/users/:id(\\d+)', requireRole('admin'), updateUser);
router.post('/users/:id/status', requireRole('moderator'), setUserStatus);
router.post('/users/:id/grant', requireRole('admin'), grantAdjust);
router.get('/users/:id/export', requireRole('admin'), exportUserData);
router.post('/users/:id/firebase', requireRole('admin'), setFirebaseDisabled);
router.delete('/users/:id(\\d+)', requireRole('super'), hardDeleteUser);

// Support console: moderators read, admins write. Every write is audited.
router.get('/support/help', listHelp);
router.put('/support/help/:id(\\d+)', requireRole('admin'), updateHelp);
router.get('/support/faqs', listFaqs);
router.put('/support/faqs/:id(\\d+)', requireRole('admin'), updateFaq);
router.get('/support/messages', listMessages);
router.get('/support/messages/:id(\\d+)', getMessage);
router.put('/support/messages/:id(\\d+)', requireRole('admin'), updateMessage);
router.post('/support/messages/:id(\\d+)/replies', requireRole('admin'), replyToMessage);
router.post('/support/messages/:id(\\d+)/read', requireRole('moderator'), markMessageRead);
router.get('/support/unread-count', getUnreadCount);
router.get('/support/insights', getInsights);

// Audit log
router.get('/moderation', listModeration);

// Exports (PII — admin and above)
router.get('/export/users.csv', requireRole('admin'), exportUsersCsv);
router.get('/export/attempts.csv', requireRole('admin'), exportAttemptsCsv);
router.get('/export/tracks.csv', requireRole('admin'), exportTracksCsv);

// System config + admin registry. Granting panel privileges is available to
// any admin (that is how new admins are appointed); only supers may remove
// admins or view the registry.
router.get('/config', getConfigValues);
router.put('/config', requireRole('admin'), updateConfigValues);
router.post('/admins', requireRole('admin'), addAdmin);
router.get('/admins', requireRole('admin'), listAdmins);
router.delete('/admins/:email', requireRole('super'), removeAdmin);

module.exports = router;
