abstract class BoardChecker() of WhiteChecker | BlackChecker {}
final class BlackChecker() extends BoardChecker() {}
final class WhiteChecker() extends BoardChecker() {}