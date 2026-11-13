function performanceNumber(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  const parsed = Number.parseFloat(String(value ?? '').replace(/[^0-9.-]/g, ''));
  return Number.isFinite(parsed) ? parsed : null;
}

function nestedPerformanceValues(student) {
  const classTestNames = ['classtest', 'class_test'];
  const monthlyTestNames = ['monthlytest', 'monthly_test'];
  const performanceValues = {
    classTestMark: null,
    classTestTotal: null,
    monthlyTestMark: null,
    monthlyTestTotal: null,
  };
  const queries = [
    { key: 'classTestMark', names: classTestNames },
    { key: 'classTestTotal', names: [...classTestNames, 'totalmark', 'maxmark'] },
    { key: 'monthlyTestMark', names: monthlyTestNames },
    { key: 'monthlyTestTotal', names: [...monthlyTestNames, 'totalmark', 'maxmark'] },
  ];

  const visit = (value, path = '') => {
    if (!value || typeof value !== 'object' ||
        queries.every(({ key }) => performanceValues[key] != null)) {
      return;
    }

    for (const [key, child] of Object.entries(value)) {
      const normalizedKey = key.toLowerCase().replace(/[^a-z0-9]/g, '');
      const normalizedPath = `${path}${normalizedKey}`;
      const matchingQueries = queries.filter(({ key: resultKey, names }) =>
        performanceValues[resultKey] == null &&
        names.some((name) => normalizedPath.includes(name)),
      );
      if (matchingQueries.length > 0) {
        const number = performanceNumber(child);
        if (number != null) {
          for (const { key: resultKey } of matchingQueries) {
            performanceValues[resultKey] = number;
          }
        }
      }

      visit(child, `${normalizedPath}.`);
      if (queries.every(({ key: resultKey }) => performanceValues[resultKey] != null)) return;
    }
  };

  visit(student);
  return performanceValues;
}

function performancePhoto(student) {
  return student.imageUrl || student.photo || student.profileImage || '';
}

function buildCampaignPerformance(students) {
  const classTestResults = [];
  const monthlyTestResults = [];
  let achievedStudents = 0;

  for (const student of students) {
    if (student.achieved === true || String(student.status || '').toLowerCase() === 'achieved') {
      achievedStudents += 1;
    }

    const {
      classTestMark,
      classTestTotal,
      monthlyTestMark,
      monthlyTestTotal,
    } = nestedPerformanceValues(student);
    if (classTestMark != null) {
      classTestResults.push({
        name: student.name || student.studentId || '',
        className: [student.className, student.section].filter(Boolean).join('-'),
        photoUrl: performancePhoto(student),
        testName: 'Class Test',
        mark: classTestMark,
        totalMark: classTestTotal || 100,
      });
    }
    if (monthlyTestMark != null) {
      monthlyTestResults.push({
        name: student.name || student.studentId || '',
        className: [student.className, student.section].filter(Boolean).join('-'),
        photoUrl: performancePhoto(student),
        testName: 'Monthly Test',
        mark: monthlyTestMark,
        totalMark: monthlyTestTotal || 100,
      });
    }
  }

  classTestResults.sort((a, b) => b.mark - a.mark);
  monthlyTestResults.sort((a, b) => b.mark - a.mark);

  const withRanks = (results) => {
    if (!results.length) return [];
    const highest = results[0].mark;
    return results
      .filter((item) => item.mark === highest)
      .map((item) => ({ ...item, rank: 1 }));
  };
  const totalStudents = students.length;
  return {
    success: true,
    data: {
      totalStudents,
      achievedStudents,
      achievementPercentage: totalStudents ? (achievedStudents / totalStudents) * 100 : 0,
      classTestToppers: withRanks(classTestResults),
      monthlyTestToppers: withRanks(monthlyTestResults),
    },
  };
}

module.exports = { buildCampaignPerformance };
