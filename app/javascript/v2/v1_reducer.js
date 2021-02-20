import { combineReducers } from "@reduxjs/toolkit";
import { normalize } from "normalizr";
import update from "immutability-helper";

import {
    board as boardSchema,
    repo as repoSchema,
    boardTicket as boardTicketSchema
} from "../schema";

const updateEntities = (updates, entities) => {
    for (const type in updates) {
        const entitiesById = updates[type];

        for (const id in entitiesById) {
            const record = entitiesById[id];

            entities = update(entities, {
                [type]: {
                    [id]: (current = {}) => update(current, { $merge: record })
                }
            });
        }
    }

    return entities;
};

const current = (state = {}, { type, payload }) => {
    switch (type) {
        case "FULL_TICKET_LOADED":
            return { ...state, boardTicket: payload.id };
        case "TICKET_MODAL_CLOSED":
            return state.boardTicket === payload.boardTicketId
                ? { ...state, boardTicket: null }
                : state;
        default:
            return state;
    }
};

const initialEntitiesState = {
    boards: {},
    repos: {},
    swimlanes: {},
    boardTickets: {},
    tickets: {},
    pullRequests: {},
    labels: {},
    milestones: {},
    comments: {}
};

const entitiesReducer = (state = initialEntitiesState, { type, payload }) => {
    switch (type) {
        case "TICKET_MOVED": {
            const { sourceId, sourceIndex, destinationId, destinationIndex } = payload;
            const movedCard = state.swimlanes[sourceId].board_tickets[sourceIndex];

            const transforms = [
                {
                    // Remove card from source swimlane...
                    [sourceId]: {
                        board_tickets: { $splice: [[sourceIndex, 1]] }
                    }
                },
                {
                    // ...and place it in destination swimlane
                    [destinationId]: {
                        board_tickets: { $splice: [[destinationIndex, 0, movedCard]] }
                    }
                }
            ];

            return transforms.reduce(
                (state, transform) => update(state, { swimlanes: transform }),
                state
            );
        }
        case "TICKET_WAS_MOVED": {
            const { destinationId, destinationIndex } = payload;
            let { boardTicket } = payload;

            if (typeof boardTicket === "string") boardTicket = JSON.parse(boardTicket);

            // Add board ticket to db
            const newEntities = updateEntities(
                normalize(boardTicket, boardTicketSchema).entities,
                state
            );

            const transforms = [];

            // Remove board ticket from wherever we have it currently (if at all)
            Object.values(newEntities.swimlanes).forEach(swimlane =>
                swimlane.board_tickets.forEach((boardTicketId, index) => {
                    if (boardTicketId === boardTicket.id) {
                        transforms.push({
                            swimlanes: {
                                [swimlane.id]: {
                                    board_tickets: { $splice: [[index, 1]] }
                                }
                            }
                        });
                    }
                })
            );

            const currentBoardTicketCount =
                newEntities.swimlanes[destinationId].board_tickets.length;

            if (currentBoardTicketCount >= destinationIndex) {
                transforms.push({
                    swimlanes: {
                        [destinationId]: {
                            board_tickets: {
                                $splice: [[destinationIndex, 0, boardTicket.id]]
                            }
                        }
                    }
                });
            }

            return transforms.reduce(
                (state, transform) => update(state, transform),
                newEntities
            );
        }
        case "SWIMLANE_TICKETS_LOADED": {
            const { board_tickets, ...swimlane } = payload;

            const { entities, result: boardTicketIds } = normalize(board_tickets, [
                boardTicketSchema
            ]);

            const newEntities = updateEntities(entities, state);

            return update(newEntities, {
                swimlanes: {
                    [swimlane.id]: {
                        $merge: swimlane,
                        board_tickets: { $push: boardTicketIds }
                    }
                }
            });
        }
        case "BOARD_TICKET_LOADED":
        case "FULL_TICKET_LOADED":
            return updateEntities(normalize(payload, boardTicketSchema).entities, state);
        default:
            return state;
    }
};

const rootReducer = combineReducers({
    entities: entitiesReducer,
    current
});

export default rootReducer;
