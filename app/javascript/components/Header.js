import React from 'react';

const Header = (props) => {
    return (
        <div className="board-header">
            <div className="ui selection dropdown">
                <i className="dropdown icon" />
                <div className="default text">{props.board.name}</div>
                <div className="menu">
                    <a className="item" href="#">{props.board.other_name}</a>
                </div>
            </div>
        </div>
    );
}

export default Header;
