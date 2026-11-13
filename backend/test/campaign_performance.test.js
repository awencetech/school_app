const test = require('node:test');
const assert = require('node:assert/strict');
const { buildCampaignPerformance } = require('../campaign_performance');

function performanceNumber(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  const parsed = Number.parseFloat(String(value ?? '').replace(/[^0-9.-]/g, ''));
  return Number.isFinite(parsed) ? parsed : null;
}

function nestedPerformanceValue(student, names) {
  const normalizedNames = names.map((name) => name.toLowerCase());
  const visit = (value, path = '') => {
    if (!value || typeof value !== 'object') return null;
    for (const [key, child] of Object.entries(value)) {
      const normalizedKey = key.toLowerCase().replace(/[^a-z0-9]/g, '');
      const normalizedPath = `${path}${normalizedKey}`;
      if (normalizedNames.some((name) => normalizedPath.includes(name))) {
        const number = performanceNumber(child);
        if (number != null) return number;
      }
      const nested = visit(child, `${normalizedPath}.`);
      if (nested != null) return nested;
    }
    return null;
  };
  return visit(student);
}

function legacyCampaignPerformance(students) {
  const makeResults = (testNames, testName) => students
    .map((student) => {
      const mark = nestedPerformanceValue(student, testNames);
      if (mark == null) return null;
      const totalMark = nestedPerformanceValue(student, [...testNames, 'totalmark', 'maxmark']) || 100;
      return {
        name: student.name || student.studentId || '',
        className: [student.className, student.section].filter(Boolean).join('-'),
        photoUrl: student.imageUrl || student.photo || student.profileImage || '',
        testName,
        mark,
        totalMark,
      };
    })
    .filter(Boolean)
    .sort((a, b) => b.mark - a.mark);
  const withRanks = (results) => {
    if (!results.length) return [];
    const highest = results[0].mark;
    return results
      .filter((item) => item.mark === highest)
      .map((item) => ({ ...item, rank: 1 }));
  };
  const achievedStudents = students.filter((student) =>
    student.achieved === true || String(student.status || '').toLowerCase() === 'achieved',
  ).length;
  return {
    success: true,
    data: {
      totalStudents: students.length,
      achievedStudents,
      achievementPercentage: students.length ? (achievedStudents / students.length) * 100 : 0,
      classTestToppers: withRanks(makeResults(['classtest', 'class_test'], 'Class Test')),
      monthlyTestToppers: withRanks(makeResults(['monthlytest', 'monthly_test'], 'Monthly Test')),
    },
  };
}

test('one-pass campaign calculations preserve nested score and total-mark behavior', () => {
  const students = [
    {
      name: 'Student One',
      studentId: 'S1',
      className: 'Class A',
      section: 'A',
      photo: 'photo-one.png',
      status: 'Achieved',
      assessments: {
        totalMark: '100 marks',
        class_test: '84/100',
        monthlyTest: 0,
      },
    },
    {
      studentId: 'S2',
      className: 'Class B',
      section: 'C',
      profileImage: 'photo-two.png',
      achieved: true,
      results: [
        { term: { classTest: '91 points', maxMark: 100 } },
        { monthly_test: '91' },
      ],
    },
    {
      name: 'Student Three',
      assessmentData: {
        class: { test: 'ignored' },
        Monthly_Test: '72.5/80',
      },
      status: ' achieved ',
    },
    { name: 'No marks', status: 'pending' },
  ];

  assert.deepEqual(buildCampaignPerformance(students), legacyCampaignPerformance(students));
});

test('campaign report preserves equal-score tie ordering and empty response values', () => {
  const tied = [
    { name: 'First', classTest: 90, totalMark: 100 },
    { name: 'Second', class_test: 90, totalMark: 100 },
    { name: 'Lower', classTest: 80, totalMark: 100 },
  ];
  assert.deepEqual(buildCampaignPerformance(tied), legacyCampaignPerformance(tied));
  assert.deepEqual(buildCampaignPerformance([]), legacyCampaignPerformance([]));
});

test('campaign report preserves nested array paths, total-mark precedence, zero fallback, and student details', () => {
  const students = [
    {
      name: 'Zero Student',
      studentId: 'S0',
      className: 'Class Zero',
      section: 'A',
      photo: 'zero.png',
      classTest: 0,
      monthly_test: 0,
      achieved: true,
    },
    {
      name: 'Array Student',
      className: 'Class A',
      section: 'B',
      profileImage: 'array.png',
      maxMark: '80 marks',
      results: [{ class_test: '68.5 points', monthlyTest: '74 points' }],
      status: 'pending',
    },
  ];

  const result = buildCampaignPerformance(students);
  assert.deepEqual(result, legacyCampaignPerformance(students));
  assert.deepEqual(result, {
    success: true,
    data: {
      totalStudents: 2,
      achievedStudents: 1,
      achievementPercentage: 50,
      classTestToppers: [{
        name: 'Array Student',
        className: 'Class A-B',
        photoUrl: 'array.png',
        testName: 'Class Test',
        mark: 68.5,
        totalMark: 80,
        rank: 1,
      }],
      monthlyTestToppers: [{
        name: 'Array Student',
        className: 'Class A-B',
        photoUrl: 'array.png',
        testName: 'Monthly Test',
        mark: 74,
        totalMark: 80,
        rank: 1,
      }],
    },
  });
  assert.equal(result.data.classTestToppers[0].totalMark, 80);
  assert.equal(result.data.monthlyTestToppers[0].totalMark, 80);

  const zeroMarkResult = buildCampaignPerformance([students[0]]);
  assert.deepEqual(zeroMarkResult, legacyCampaignPerformance([students[0]]));
  assert.equal(zeroMarkResult.data.classTestToppers[0].totalMark, 100);
  assert.equal(zeroMarkResult.data.monthlyTestToppers[0].totalMark, 100);
});
