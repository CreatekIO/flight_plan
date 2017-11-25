import React from 'react';

import Header from './Header'

const Application = () => {
    const board = { name: 'Other Board', other_name: 'Other 12' }

    return (
        <Header board={board}/>
    );
}

export default Application
