function levelFromScore(score) {
  return score >= 90 ? 'platinum' : score >= 75 ? 'gold' : score >= 50 ? 'silver' : 'bronze';
}

module.exports = { levelFromScore };
