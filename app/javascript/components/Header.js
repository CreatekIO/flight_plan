import React from "react";

const Header = props => {
    const listItems = props.boards.map(item => (
        <a className="item" href="#">
            {item}
        </a>
    ));
    return (
        <div className="board-header">
            <div className="ui selection dropdown">
                <i className="dropdown icon" />
                <div className="default text">{props.boards[0]}</div>
                <div className="menu">
                    {listItems}
                    <div />
                </div>
            </div>
        </div>
    );
};

export default Header;
