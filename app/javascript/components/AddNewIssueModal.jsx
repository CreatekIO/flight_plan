import React, { Component } from 'react';
import { connect } from 'react-redux';
import { Button, Header, Image, Modal, Select, Form } from 'semantic-ui-react';
import { ticketCreated } from '../action_creators';

class AddNewIssueForm extends Component {
    state = {
        title: '',
        description: ''
    };

    handleChange = (e, { name, value }) => {
        this.setState({ [name]: value });
    };

    handleSubmit = () => {
        ticketCreated(this.state);
    };

    boardRepos = () => {
        return flightPlanConfig.currentBoardRepos.map((repo, index, array) => ({
            key: index,
            text: repo.name,
            value: repo.id
        }));
    };

    render() {
        return (
            <Form onSubmit={this.handleSubmit}>
                <div className="field">
                    <label>Repository</label>
                    <Select
                        placeholder={this.boardRepos()[0].text}
                        name="repo_id"
                        options={this.boardRepos()}
                        onChange={this.handleChange}
                    />
                </div>
                <Form.Input
                    label={'Title'}
                    placeholder={'Issue title'}
                    name="title"
                    onChange={this.handleChange}
                />
                <Form.TextArea
                    label={'Description'}
                    placeholder={'Issue description'}
                    name="description"
                    onChange={this.handleChange}
                />
                <Form.Button>Submit</Form.Button>
            </Form>
        );
    }
}

const AddNewIssueModal = () => (
    <Modal
        id={'add-new-issue-modal'}
        trigger={<a className="item">Add an issue</a>}>
        <Modal.Header>Add a new issue</Modal.Header>
        <Modal.Content>
            <AddNewIssueForm />
        </Modal.Content>
    </Modal>
);

export default AddNewIssueModal;
