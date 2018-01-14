import backgammon.server.bus {

	PlayerRosterEventBus
}
import io.vertx.ceylon.core {

	Vertx
}
import io.vertx.ceylon.web {

	routerFactory=router,
	Router,
	RoutingContext
}
import backgammon.shared {

	PlayerStatisticUpdateMessage,
	PlayerStatistic,
	PlayerTransaction,
	PlayerDetailOutputMessage,
	applicationMessages
}

final class PlayerRosterRouterFactory(Vertx vertx, ServerConfiguration serverConfig) {
	
	value repoEventBus = PlayerRosterEventBus(vertx, serverConfig);

	// TODO revisit later
	function playerTransactionType(PlayerStatisticUpdateMessage update) {
		if (update.isBet) {
			return "Bet";
		} else if (update.isWonGame) {
			return "Game won";
		} else if (update.isRefund) {
			return "Refund";
		} else if (update.isLogin) {
			return "Login";
		} else {
			return "Unknown";
		}
	}
	
	function toPlayerTransaction(PlayerStatisticUpdateMessage update) {
		return PlayerTransaction(playerTransactionType(update), update.statisticDelta.balance, update.timestamp);
	}

	void handlePlayerDetailRequest(RoutingContext rc) {
		value context = GameRoomRoutingContext(rc);
	
		if (exists playerInfo = context.getCurrentPlayerInfo()) {
			void buildPlayerDetailResult({PlayerStatisticUpdateMessage*}|Throwable result) {
				if (is Throwable result) {
					context.fail(result);
				} else {
					value statistic = result.fold(PlayerStatistic())((s, u) => s + u.statisticDelta);
					value transactions = result.filter(PlayerStatisticUpdateMessage.hasBalanceDelta).map(toPlayerTransaction);
					value output = PlayerDetailOutputMessage(playerInfo, statistic, transactions.sequence());
					context.writeJsonResponse(applicationMessages.format(output));
				}
			}
			
			repoEventBus.queryPlayerTransactions(playerInfo.playerId, buildPlayerDetailResult);
		}
	}
	
	shared Router createApiRouter() {
		value restApi = routerFactory.router(vertx);
		restApi.get("/playerdetail").handler(handlePlayerDetailRequest);
		return restApi;
	}
}